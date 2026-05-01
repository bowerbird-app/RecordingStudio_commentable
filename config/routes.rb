# frozen_string_literal: true

RecordingStudioCommentable::Engine.routes.draw do
  root "home#index"

  resources :recordings, only: [] do
    resources :comments, only: %i[index new create edit update destroy] do
      collection do
        get :all, path: "all"
      end
    end
  end
end
