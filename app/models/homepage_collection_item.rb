class HomepageCollectionItem < ApplicationRecord
  include SoftDeletable
  include OrganizedUploads

  belongs_to :homepage_collection
  has_one_attached :image

  upload_key_prefix { "admin/collections" }

  validate :validate_image_size
  validate :validate_image_content_type

  scope :ordered, -> { order(:position, :created_at) }

  MAX_IMAGE_SIZE = 2.megabytes

  OVERLAY_POSITIONS = {
    "bottom_left" => "Bottom Left",
    "bottom_center" => "Bottom Center",
    "center" => "Center",
    "top_left" => "Top Left",
    "top_center" => "Top Center",
    "hidden" => "No Overlay"
  }.freeze

  def overlay_position_class
    case overlay_position
    when "bottom_left" then "items-end justify-start text-left"
    when "bottom_center" then "items-end justify-center text-center"
    when "center" then "items-center justify-center text-center"
    when "top_left" then "items-start justify-start text-left"
    when "top_center" then "items-start justify-center text-center"
    when "hidden" then "hidden"
    else "items-end justify-start text-left"
    end
  end

  private

  def validate_image_size
    return unless image.attached?
    if image.blob.byte_size > MAX_IMAGE_SIZE
      errors.add(:image, "must be less than 2 MB (uploaded: #{(image.blob.byte_size / 1.megabyte.to_f).round(1)} MB)")
    end
  end

  def validate_image_content_type
    return unless image.attached?
    unless image.blob.content_type.in?(%w[image/jpeg image/png image/webp])
      errors.add(:image, "must be a JPG, PNG, or WebP file")
    end
  end
end
