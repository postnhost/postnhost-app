require "carrierwave"
require "carrierwave-aws"
require "carrierwave/storage/aws"

CarrierWave.configure do |config|
  if Rails.env.production?
    config.storage = :aws
    config.aws_bucket = Rails.application.credentials.dig(:postnhost, :aws_bucket_name)
    config.aws_acl = "public-read"

    config.aws_credentials = {
      access_key_id: Rails.application.credentials.dig(:postnhost, :aws_access_key_id),
      secret_access_key: Rails.application.credentials.dig(:postnhost, :aws_secret_access_key),
      region: Rails.application.credentials.dig(:postnhost, :aws_region),
      endpoint: Rails.application.credentials.dig(:postnhost, :aws_endpoint_url_s3),
      stub_responses: Rails.env.test?
    }
  else
    config.storage = :file
  end
end
