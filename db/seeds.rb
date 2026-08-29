# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Languages with i18n translations
languages_data = [
  { name: "English", html_lang: "en", default: true },
  { name: "French", html_lang: "fr", default: false },
  { name: "German", html_lang: "de", default: false },
  { name: "Japanese", html_lang: "ja", default: false },
  { name: "Korean", html_lang: "ko", default: false },
  { name: "Portuguese", html_lang: "pt", default: false },
  { name: "Polish", html_lang: "pl", default: false },
  { name: "Spanish", html_lang: "es", default: false },
  { name: "Russian", html_lang: "ru", default: false }
]

puts "Creating languages..."
languages_data.each do |lang_data|
  language = Postnhost::Language.find_or_create_by!(name: lang_data[:name]) do |lang|
    lang.html_lang = lang_data[:html_lang]
    lang.default = lang_data[:default]
  end
  puts "✓ Created/found language: #{language.name} (#{language.html_lang})"
end

puts "\nRequired seed data created successfully!"
puts "Languages: #{Postnhost::Language.count}"
