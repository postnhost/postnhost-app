require "rails_helper"

RSpec.describe "Public articles smoke", type: :system do
  let!(:default_language) { Postnhost::Language.create!(name: "English", html_lang: "en", default: true) }
  let!(:user) do
    Postnhost::User.create!(
      name: "John Doe",
      email: "smoke-public-#{Time.current.to_i}-#{rand(10_000)}@example.com",
      password: "password",
      password_confirmation: "password"
    )
  end

  it "renders the public homepage with a published article" do
    article = Postnhost::Article.create!(
      user: user,
      language: default_language,
      title: "Smoke Article",
      content: "<p>Smoke content</p>",
      meta_description: "Smoke description"
    )
    publish_result = Postnhost::Publishing::Articles::Publish.call(article:)
    expect(publish_result).to be_success

    visit postnhost.root_path

    expect(page).to have_text(I18n.t("postnhost.public.site.blog_tagline"))
    expect(page).to have_text(article.title)
  end
end
