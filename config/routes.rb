Rails.application.routes.draw do
  mount Notifications::Engine => "/notifications"
  namespace :admin do
    resources :users
    resources :comments
    resources :communities
    resources :links
    resources :posts
    resources :topics

    root to: "users#index"
  end

  root 'home#index'

  get 'home/index'

  get 'go/:id', to: 'posts#show'

  devise_for :users, controllers: {registrations: 'registrations'}
  resources :posts do
    resources :comments
    member do
      post :vote
    end
  end
  resources :communities do
    member do
      post :follow
      post :unfollow
    end
  end
  resources :links
  resources :topics
  resources :u, controller: 'users' do
    resources :comments, except: [:index]
    get 'comments', to: 'comments#user_comments'
  end

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
