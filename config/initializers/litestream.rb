# Supports: AWS S3, Tigris, DigitalOcean Spaces, Backblaze B2, etc.

Rails.application.configure do
  # Reuse existing AWS/S3-compatible credentials
  config.litestream.replica_key_id = Rails.application.credentials.dig(:postnhost, :aws_access_key_id)
  config.litestream.replica_access_key = Rails.application.credentials.dig(:postnhost, :aws_secret_access_key)

  # S3-compatible storage settings (configure in Rails credentials)
  config.litestream.replica_bucket = Rails.application.credentials.dig(:postnhost, :litestream_bucket)
  config.litestream.replica_region = Rails.application.credentials.dig(:postnhost, :aws_region)
  config.litestream.replica_endpoint = Rails.application.credentials.dig(:postnhost, :litestream_endpoint)
end
