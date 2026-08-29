require "rails_helper"

RSpec.describe "Authentication smoke", type: :system do
  it "renders sign in page and allows user sign in" do
    user = Postnhost::User.create!(
      name: "Smoke User",
      email: "smoke-#{Time.current.to_i}-#{rand(10_000)}@example.com",
      password: "password",
      password_confirmation: "password"
    )

    visit postnhost.new_session_path

    expect(page).to have_text("Welcome back")

    fill_in "user_email", with: user.email
    fill_in "user_password", with: "password"
    click_button "Sign in"

    expect(page).to have_current_path(postnhost.articles_path, ignore_query: true)
  end
end
