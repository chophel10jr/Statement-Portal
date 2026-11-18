Rails.application.routes.draw do
  root to: 'statement#new'
  resources :statement, only: [:new, :create]
  get "/statement/:filename", to: "statement#show", as: :statement

  resources :verification, only: [] do
    collection do
      get  :verify_otp_form
      post :verify_otp
      post :resend_otp
    end
  end
end
