require "rails_helper"

RSpec.describe "Engine mount smoke", type: :request do
  it "serves postnhost root from mounted engine" do
    Postnhost::Language.create!(name: "English", html_lang: "en", default: true)
    Postnhost::User.create!(name: "Admin", email: "admin@example.com", password: "password")

    get "/"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("<html lang=\"en\" data-postnhost>")
    expect(response.body).to include("postnhost/application")
    expect(response.body).not_to include("postnhost/host")
  end
end
