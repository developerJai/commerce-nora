# Serve Active Storage uploads through CloudFront CDN in production.
#
# How it works:
#   1. Views use `image_tag attachment` which generates a relative path:
#      /rails/active_storage/blobs/redirect/:signed_id/:filename
#
#   2. When the browser hits that URL, Rails calls @blob.url to get the
#      redirect destination. We override this to return the CloudFront URL
#      instead of a raw S3 signed URL.
#
#   3. Rails responds with 302 → https://CDN_HOST/:blob_key
#      Browser follows redirect → CloudFront serves from S3 origin.
#
# This ONLY affects S3-hosted uploads. Local assets (CSS, JS, images in
# public/) are served directly from the app server — no CDN prefix.
#
# Requirements:
#   - CloudFront distribution with the S3 bucket as origin
#   - Bucket policy allowing CloudFront OAI/OAC to GetObject
#   - ENV["CDN_HOST"] or fallback to the hardcoded distribution domain

if Rails.env.production?
  Rails.application.config.after_initialize do
    # Read from credentials: aws.cdn_host
    # Set via: EDITOR=nano bin/rails credentials:edit
    #
    #   aws:
    #     access_key_id: AKIA...
    #     secret_access_key: ...
    #     region: ap-south-1
    #     bucket_name: your-bucket
    #     cdn_host: https://d1y6u9igsz4v3o.cloudfront.net
    #
    cdn_host = Rails.application.credentials.dig(:aws, :cdn_host)

    if cdn_host.present?
      cdn_host = cdn_host.chomp("/")
      cdn_host = "https://#{cdn_host}" unless cdn_host.start_with?("http")

      ActiveStorage::Blob.class_eval do
        define_method(:url) do |expires_in: ActiveStorage.service_urls_expire_in, disposition: :inline, filename: nil, content_type: nil|
          "#{cdn_host}/#{key}"
        end
      end

      Rails.logger.info "[ActiveStorage CDN] Serving uploads via #{cdn_host}"
    else
      Rails.logger.warn "[ActiveStorage CDN] No aws.cdn_host in credentials — using default S3 URLs"
    end
  end
end
