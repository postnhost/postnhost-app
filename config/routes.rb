Rails.application.routes.draw do
  # Skip www redirect in test environment
  match "(*any)", to: redirect(subdomain: ""), via: :all, constraints: { subdomain: "www" } unless Rails.env.test?

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Admin tools (behind custom session authentication)
  constraints ->(req) { Postnhost::User.exists?(id: req.session[:user_id]) } do
    mount MissionControl::Jobs::Engine, at: "/jobs"
    mount Litestream::Engine, at: "/litestream"
  end

  # Mount Postnhost CMS engine at root
  mount Postnhost::Engine, at: "/"
end
