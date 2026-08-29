if defined?(Bullet)
  Bullet.enable = true
  Bullet.alert = false
  Bullet.bullet_logger = true
  Bullet.console = true
  Bullet.rails_logger = true
  Bullet.add_footer = true

  Bullet.add_safelist(type: :unused_eager_loading, class_name: "Postnhost::Article", association: :article_categories)
end
