source "https://rubygems.org"

gem "postnhost", "~> 0.1"

gem "propshaft"
gem "puma"
gem "rails"
gem "sqlite3"
gem "stimulus-rails"
gem "turbo-rails"
gem "tzinfo-data", platforms: %i[windows jruby]

gem "solid_cable"
gem "solid_cache"
gem "solid_queue"

gem "bootsnap", require: false

gem "thruster", require: false

gem "aws-sdk-s3", require: false
gem "litestream"
gem "mission_control-jobs"
gem "rails-i18n"

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "rspec-rails"
end

group :development do
  gem "brakeman", require: false
  gem "bullet"
  gem "dockerfile-rails"
  gem "rubocop", require: false
  gem "rubocop-capybara", require: false
  gem "rubocop-factory_bot", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-rspec", require: false
  gem "rubocop-rspec_rails", require: false
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "database_cleaner-active_record"
  gem "factory_bot_rails"
  gem "faker"
  gem "selenium-webdriver"
  gem "shoulda-matchers"
  gem "webmock"
end
