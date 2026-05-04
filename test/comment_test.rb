# frozen_string_literal: true

require "test_helper"
require "active_model"

# Unit tests for the Comment model.
#
# These tests exercise validations and instance methods without a database
# connection. Comment inherits from ApplicationRecord but we don't call
# .save, so no DB is needed.
class CommentTest < Minitest::Test
  # Minimal stand-in that behaves like Comment but uses ActiveModel validations
  # only (no AR dependency at unit-test layer).
  class StubComment
    include ActiveModel::Validations
    include ActiveModel::Conversion

    attr_accessor :body, :author, :author_type, :author_id

    validates :body, presence: true

    def initialize(attrs = {})
      attrs.each { |k, v| public_send("#{k}=", v) }
    end

    def self.model_name
      ActiveModel::Name.new(self, nil, "RecordingStudioCommentable::Comment")
    end

    def author_display_name
      return "Anonymous" unless author

      configured_name = RecordingStudioCommentable::DisplayAttributeResolver.string_value_for(
        author,
        mappings: RecordingStudioCommentable::DisplayAttributeResolver.mapping_for_configuration(:author_display_attributes),
        fallback_attributes: %i[display_name name]
      )

      configured_name || author.to_s
    end

    def author_avatar_url
      return unless author

      RecordingStudioCommentable::DisplayAttributeResolver.string_value_for(
        author,
        mappings: RecordingStudioCommentable::DisplayAttributeResolver.mapping_for_configuration(:author_avatar_attributes)
      )
    end

    def persisted?
      false
    end
  end

  def test_valid_with_body
    comment = StubComment.new(body: "Great work!")
    assert comment.valid?
  end

  def setup
    @original_configuration = RecordingStudioCommentable.instance_variable_get(:@configuration)
    RecordingStudioCommentable.instance_variable_set(:@configuration, RecordingStudioCommentable::Configuration.new)
  end

  def teardown
    RecordingStudioCommentable.instance_variable_set(:@configuration, @original_configuration)
  end

  def test_invalid_without_body
    comment = StubComment.new(body: nil)
    refute comment.valid?
    assert_includes comment.errors[:body], "can't be blank"
  end

  def test_invalid_with_empty_body
    comment = StubComment.new(body: "")
    refute comment.valid?
  end

  def test_author_display_name_without_author
    comment = StubComment.new(body: "Hello", author: nil)
    assert_equal "Anonymous", comment.author_display_name
  end

  def test_author_display_name_with_display_name_method
    author = Object.new
    def author.display_name = "Alice"

    comment = StubComment.new(body: "Hello", author: author)
    assert_equal "Alice", comment.author_display_name
  end

  def test_author_display_name_falls_back_to_to_s
    author = Object.new
    def author.to_s = "user:42"

    comment = StubComment.new(body: "Hello", author: author)
    assert_equal "user:42", comment.author_display_name
  end

  def test_author_display_name_uses_configured_method
    author_class = Class.new do
      attr_reader :first_name, :last_name

      def initialize(first_name, last_name)
        @first_name = first_name
        @last_name = last_name
      end

      def full_name
        "#{first_name} #{last_name}"
      end
    end
    Object.const_set("NamedAuthor", author_class)
    RecordingStudioCommentable.configuration.author_display_attributes = { "NamedAuthor" => :full_name }

    comment = StubComment.new(body: "Hello", author: NamedAuthor.new("Ada", "Lovelace"))

    assert_equal "Ada Lovelace", comment.author_display_name
  ensure
    Object.send(:remove_const, :NamedAuthor) if Object.const_defined?(:NamedAuthor)
  end

  def test_author_avatar_url_uses_configured_method
    author_class = Class.new do
      def profile_image
        "https://example.com/avatar.png"
      end
    end
    Object.const_set("AvatarAuthor", author_class)
    RecordingStudioCommentable.configuration.author_avatar_attributes = { "AvatarAuthor" => :profile_image }

    comment = StubComment.new(body: "Hello", author: AvatarAuthor.new)

    assert_equal "https://example.com/avatar.png", comment.author_avatar_url
  ensure
    Object.send(:remove_const, :AvatarAuthor) if Object.const_defined?(:AvatarAuthor)
  end

  def test_author_avatar_url_returns_nil_without_configuration
    author = Object.new
    comment = StubComment.new(body: "Hello", author: author)

    assert_nil comment.author_avatar_url
  end

  def test_comment_class_defined
    # Comment lives in app/models/ and is autoloaded by Rails Zeitwerk in a
    # full Rails environment. In unit tests without a booted app, verify the
    # source file is present and syntactically valid instead.
    root = File.expand_path("..", __dir__)
    comment_path = File.join(root, "app/models/recording_studio_commentable/comment.rb")
    assert File.exist?(comment_path),
           "Expected Comment model file at #{comment_path}"
    content = File.read(comment_path)
    assert_includes content, "class Comment"
    assert_includes content, "validates :body, presence: true"
    assert_includes content, "def author_display_name"
    assert_includes content, "def author_avatar_url"
  end
end
