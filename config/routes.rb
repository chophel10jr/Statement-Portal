Rails.application.routes.draw do
  root to: 'statement#new'
  resources :statement, only: [:new, :create]

  resources :verification, only: [] do
    collection do
      get 'verify_otp/:id', to: 'verification#verify_otp_form', as: 'verify_otp'
      post 'verify_otp/:id', to: 'verification#verify_otp'
      post 'resend_otp/:id', to: 'verification#resend_otp', as: 'resend_otp'
    end
  end
end
