class Banner < ApplicationRecord
  include SoftDeletable
  has_one_attached :image

  validates :title, presence: true

  scope :active, -> { where(active: true) }
  scope :current, -> {
    now = Time.current
    where("(starts_at IS NULL OR starts_at <= ?) AND (ends_at IS NULL OR ends_at >= ?)", now, now)
  }
  scope :ordered, -> { order(:position, :created_at) }
  scope :visible, -> { active.current.ordered }

  def visible?
    active? && within_date_range?
  end

  def within_date_range?
    now = Time.current
    (starts_at.nil? || starts_at <= now) && (ends_at.nil? || ends_at >= now)
  end
end
