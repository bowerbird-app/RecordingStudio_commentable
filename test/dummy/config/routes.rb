Rails.application.routes.draw do
  devise_for :users

  # RecordingStudio engine is data/API-focused and has no browser root route.
  # Keep legacy links working by redirecting the base path to the app home.
  get "/recording_studio", to: redirect("/"), as: nil
  mount RecordingStudio::Engine, at: "/recording_studio"

  # RecordingStudioCommentable engine — comment feeds for recordings
  mount RecordingStudioCommentable::Engine, at: "/commentable"

  scope module: :recording_studio_commentable do
    resources :recordings, only: [] do
      resources :comments, only: %i[index new create edit update destroy] do
        collection do
          get :all, path: "all"
        end
      end
    end
  end

  get "/recordings", to: "home#recordings", as: :recordings_browser
  get "/recordings/:id", to: "home#recording", as: :recording_browser
  get "/scenarios", to: "home#scenarios", as: :scenarios
  get "/gem-routes", to: "home#gem_routes", as: :gem_routes
  get "/helpers", to: "home#helpers", as: :helpers
  get "/components", to: "home#components", as: :components

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"
end
