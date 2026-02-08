# Provides vendor-scoped (or entity-scoped) folder structure for Active Storage
# uploads on S3 and local disk.
#
# Usage:
#   class Product < ApplicationRecord
#     include OrganizedUploads
#
#     upload_key_prefix do
#       vendor_id ? "vendors/#{vendor_id}/products" : "products"
#     end
#   end
#
# The block is evaluated in the model instance context, so it has access to
# all attributes. It runs before_save so pending attachment blobs pick up
# the prefix via a thread-local variable read by the ActiveStorage::Blob
# initializer (see config/initializers/active_storage_organized_keys.rb).
#
# Thread-safety: the prefix is set just before save and cleared in
# after_commit / after_rollback, so it cannot leak across requests.

module OrganizedUploads
  extend ActiveSupport::Concern

  class_methods do
    # Declare the S3 key prefix for this model's uploads.
    # Pass a block that returns a string path (no leading/trailing slashes).
    def upload_key_prefix(&block)
      define_method(:_compute_upload_key_prefix, &block)
      private :_compute_upload_key_prefix
    end
  end

  included do
    before_save    :_set_upload_key_prefix
    after_commit   :_clear_upload_key_prefix
    after_rollback :_clear_upload_key_prefix
  end

  private

  def _set_upload_key_prefix
    return unless respond_to?(:_compute_upload_key_prefix, true)

    prefix = _compute_upload_key_prefix
    Thread.current[:active_storage_key_prefix] = prefix if prefix.present?
  end

  def _clear_upload_key_prefix
    Thread.current[:active_storage_key_prefix] = nil
  end
end
