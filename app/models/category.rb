class Category < ApplicationRecord
  include SoftDeletable
  belongs_to :parent, class_name: 'Category', optional: true
  has_many :children, class_name: 'Category', foreign_key: :parent_id, dependent: :nullify
  has_many :products, dependent: :nullify

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  scope :active, -> { where(active: true) }
  scope :root, -> { where(parent_id: nil) }
  scope :ordered, -> { order(:position, :name) }

  def self.tree
    root.active.ordered.includes(:children)
  end

  private

  def generate_slug
    self.slug = name.parameterize
  end
end
