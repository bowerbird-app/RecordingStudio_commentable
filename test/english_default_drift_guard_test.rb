# frozen_string_literal: true

require "test_helper"

# Ensures production call sites for gem keys do not hand-copy English from
# en.yml (or constants equal to those strings) as `default:`. English fallback
# comes from RecordingStudio.t / RecordingStudio::Translation / loaded :en.
#
# Scanner covers RecordingStudio.t, I18n.t, I18n.translate, and view t(
# (single-quoted, double-quoted, multi-line, paren-less, constant, Array).
#
# Companion rule: recording_studio.commentable.* lookups in app/ and lib/ must
# use RecordingStudio.t (not plain I18n.t or bare t(). Admin DSL stays literal
# (none in this gem).
class EnglishDefaultDriftGuardTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  SCAN_GLOBS = %w[
    app/**/*.{rb,erb}
    lib/**/*.rb
  ].freeze
  SKIP_PATH_FRAGMENTS = %w[
    /generators/
  ].freeze
  COMMENTABLE_KEY = /recording_studio\.commentable\./

  # Longer names first so I18n.translate is not eaten by I18n.t.
  # Bare t must be a call (t( / t " / t '), not the leading t in text:/title:.
  TRANSLATION_CALL = /
    (?:
      RecordingStudio::Translation\.t |
      RecordingStudio\.t |
      I18n\.translate |
      I18n\.t |
      (?<![[:alnum:]_:@.])t(?=\s*[("' ])
    )
  /x

  def test_production_translation_calls_do_not_hand_copy_en_yml_english_defaults
    en_values = en_yml_leaf_values
    constant_values = known_message_constants

    offenders = []
    scan_files.each do |path|
      source = File.read(path)
      source = strip_ruby_comments(source) if path.end_with?(".rb")

      each_translation_call(source) do |call_source|
        each_default_argument(call_source) do |default_src|
          next if allowed_dynamic_default?(default_src)

          values = default_values(default_src, constant_values)
          values.each do |value|
            next unless en_values.include?(value)

            offenders << "#{relative(path)}: default: #{default_src} => #{value.inspect}"
          end
        end
      end
    end

    assert_empty offenders, <<~MSG
      Hand-copied English default:s drift from en.yml. Remove them and rely on
      RecordingStudio.t / RecordingStudio::Translation fallback instead.
      #{offenders.join("\n")}
    MSG
  end

  def test_production_commentable_keys_use_recording_studio_t
    offenders = []

    scan_files.each do |path|
      source = File.read(path)
      source = strip_ruby_comments(source) if path.end_with?(".rb")

      each_translation_call(source) do |call_source, method_name|
        next unless commentable_key_lookup?(call_source)
        next if recording_studio_t_call?(method_name)

        offenders << "#{relative(path)}: #{method_name.strip} must be RecordingStudio.t " \
                     "for commentable keys (saw #{call_source.lines.first.to_s.strip})"
      end
    end

    assert_empty offenders, <<~MSG
      recording_studio.commentable.* call sites must use RecordingStudio.t
      (not I18n.t / I18n.translate / bare t(). Admin DSL literals are exempt;
      this gem has none).
      #{offenders.join("\n")}
    MSG
  end

  def test_scanner_catches_single_quoted_multiline_paren_less_translate_constant_and_array_defaults
    sample = <<~RUBY
      RecordingStudio.t("recording_studio.commentable.home.title", default: 'All comments')
      RecordingStudio.t(
        "recording_studio.commentable.common.add_comment",
        default: "Add comment"
      )
      t "recording_studio.commentable.common.comments", default: "Comments"
      I18n.translate("recording_studio.commentable.composer.post", default: "Post comment")
      I18n.t("recording_studio.commentable.empty.title", default: EMPTY_TITLE_MESSAGE)
      RecordingStudio.t("recording_studio.commentable.home.title", default: ["All comments", "Other"])
    RUBY

    en_values = en_yml_leaf_values
    constant_values = { "EMPTY_TITLE_MESSAGE" => "No comments yet" }
    hits = []

    each_translation_call(sample) do |call_source|
      each_default_argument(call_source) do |default_src|
        hits.concat(default_values(default_src, constant_values).select { |value| en_values.include?(value) })
      end
    end

    assert_includes hits, "All comments"
    assert_includes hits, "Add comment"
    assert_includes hits, "Comments"
    assert_includes hits, "Post comment"
    assert_includes hits, "No comments yet"
    assert_equal 2, hits.count("All comments"), "array + single-quoted All comments"
  end

  def test_scanner_flags_bare_t_and_i18n_t_commentable_lookups
    sample = <<~RUBY
      RecordingStudio.t("recording_studio.commentable.home.title")
      I18n.t("recording_studio.commentable.common.comments")
      t("recording_studio.commentable.empty.title")
      I18n.translate("recording_studio.commentable.composer.post")
    RUBY

    flagged = []
    each_translation_call(sample) do |call_source, method_name|
      next unless commentable_key_lookup?(call_source)
      next if recording_studio_t_call?(method_name)

      flagged << method_name.strip
    end

    assert_includes flagged, "I18n.t"
    assert_includes flagged, "t"
    assert_includes flagged, "I18n.translate"
    refute_includes flagged, "RecordingStudio.t"
  end

  private

  def scan_files
    SCAN_GLOBS.flat_map { |glob| Dir[File.join(ROOT, glob)] }
              .uniq
              .reject { |path| SKIP_PATH_FRAGMENTS.any? { |frag| path.include?(frag) } }
  end

  def relative(path)
    path.delete_prefix("#{ROOT}/")
  end

  def en_yml_leaf_values
    tree = YAML.safe_load_file(File.join(ROOT, "config/locales/en.yml"), aliases: true)
               .fetch("en").fetch("recording_studio").fetch("commentable")
    flatten_values(tree).to_set
  end

  def flatten_values(node)
    case node
    when Hash then node.values.flat_map { |value| flatten_values(value) }
    when Array then node.flat_map { |value| flatten_values(value) }
    else [node]
    end
  end

  def known_message_constants
    {}
  end

  def strip_ruby_comments(source)
    source.gsub(/^\s*#.*$/, "")
  end

  def each_translation_call(source)
    index = 0
    while (match = source.match(TRANSLATION_CALL, index))
      method_name = match[0]
      start = match.end(0)
      call_body = extract_call_body(source, start, method_name)
      yield "#{method_name}#{call_body}", method_name
      index = start + 1
    end
  end

  def extract_call_body(source, start, method_name)
    return paren_body(source, start) if source[start] == "("
    if method_name.strip.match?(/\A(?:t|I18n\.(?:t|translate)|RecordingStudio\.t|RecordingStudio::Translation\.t)\z/)
      return " #{slice_until_newline(source, start)}"
    end

    ""
  end

  def paren_body(source, open_index)
    depth = 0
    i = open_index
    while i < source.length
      case source[i]
      when "(" then depth += 1
      when ")"
        depth -= 1
        return source[open_index..i] if depth.zero?
      when "'", '"'
        i = skip_string(source, i)
        next
      end
      i += 1
    end
    source[open_index..]
  end

  def skip_string(source, index)
    quote = source[index]
    index += 1
    while index < source.length
      return index + 1 if source[index] == quote && source[index - 1] != "\\"

      index += 1
    end
    index
  end

  def slice_until_newline(source, start)
    line_end = source.index(/\n/, start) || source.length
    source[start...line_end]
  end

  def each_default_argument(call_source)
    offset = 0
    while (match = call_source.match(/default:\s*/, offset))
      value = read_ruby_expression(call_source, match.end(0))
      yield value.strip
      offset = match.end(0) + value.length
    end
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def read_ruby_expression(source, start)
    i = start
    i += 1 while i < source.length && source[i].match?(/\s/)
    return "" if i >= source.length

    case source[i]
    when "'", '"'
      finish = skip_string(source, i)
      source[i...finish]
    when "["
      depth = 0
      j = i
      while j < source.length
        case source[j]
        when "[" then depth += 1
        when "]"
          depth -= 1
          return source[i..j] if depth.zero?
        when "'", '"'
          j = skip_string(source, j)
          next
        end
        j += 1
      end
      source[i..]
    else
      j = i
      j += 1 while j < source.length && source[j].match?(/[A-Za-z0-9_:]/)
      source[i...j]
    end
  end

  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def allowed_dynamic_default?(default_src)
    normalized = default_src.gsub(/\s+/, "")
    %w[name.humanize].include?(normalized)
  end

  def default_values(default_src, constant_values)
    if string_literal_default?(default_src)
      [eval_string_literal(default_src)]
    elsif array_literal_default?(default_src)
      extract_array_string_literals(default_src)
    elsif constant_default?(default_src)
      leaf = default_src.split("::").last
      Array(constant_values[default_src] || constant_values[leaf])
    else
      []
    end
  end

  def string_literal_default?(default_src)
    default_src.match?(/\A(['"]).*\1\z/m)
  end

  def array_literal_default?(default_src)
    default_src.start_with?("[")
  end

  def constant_default?(default_src)
    default_src.match?(/\A[A-Z][A-Za-z0-9_:]+\z/)
  end

  def eval_string_literal(literal)
    # rubocop:disable Security/Eval
    eval(literal)
    # rubocop:enable Security/Eval
  end

  def extract_array_string_literals(array_src)
    array_src.scan(/(['"])((?:\\.|(?!\1).)*)\1/).map do |quote, body|
      eval_string_literal("#{quote}#{body}#{quote}")
    end
  end

  def commentable_key_lookup?(call_source)
    call_source.match?(COMMENTABLE_KEY) ||
      call_source.match?(/scope:\s*["']recording_studio\.commentable/)
  end

  def recording_studio_t_call?(method_name)
    method_name.strip.match?(/\A(?:RecordingStudio\.t|RecordingStudio::Translation\.t)\z/)
  end
end
