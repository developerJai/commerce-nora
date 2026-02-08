# Organize Active Storage uploads into nested folders on S3 (and Disk in dev).
#
# When a model includes the OrganizedUploads concern and declares an
# `upload_key_prefix`, newly created blobs get a structured key like:
#
#   vendors/42/products/abc123def456.jpg
#   admin/banners/xyz789.png
#
# Existing blobs with random keys continue to work — only new uploads
# are affected. Works identically on Disk (development) and S3 (production).

Rails.application.config.after_initialize do
  ActiveStorage::Blob.class_eval do
    before_create :apply_organized_key_prefix

    private

    def apply_organized_key_prefix
      prefix = Thread.current[:active_storage_key_prefix]
      return if prefix.blank?

      ext   = filename.extension_with_delimiter
      token = SecureRandom.base36(28)
      self.key = "#{prefix}/#{token}#{ext}"
    end
  end
end
