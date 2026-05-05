# frozen_string_literal: true

RecordingStudioCommentable::Engine.routes.draw do
  root "home#index"

  resources :comments, only: [] do
    member do
      get :reply
      post :reply, action: :create_reply
    end
  end
end
