class Category < ApplicationRecord
  include SoftDeletable

  # ── Associations ──────────────────────────────────────────────────
  belongs_to :parent, class_name: 'Category', optional: true
  has_many :children, class_name: 'Category', foreign_key: :parent_id, dependent: :nullify
  has_many :products, dependent: :nullify
  has_one_attached :image

  # ── Validations ───────────────────────────────────────────────────
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validate :parent_cannot_be_self
  validate :prevent_deep_nesting

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  # ── Scopes ────────────────────────────────────────────────────────
  scope :active, -> { where(active: true) }
  scope :root, -> { where(parent_id: nil) }
  scope :subcategories, -> { where.not(parent_id: nil) }
  scope :ordered, -> { order(:position, :name) }

  # ── Tree queries ──────────────────────────────────────────────────

  def self.tree
    root.active.ordered.includes(children: { image_attachment: :blob })
  end

  # Returns category tree for storefront filters.
  # When product_counts hash is given, hides parent categories with 0 products.
  # Subcategories are always shown if active (not filtered by product count).
  def self.grouped_for_filters(product_counts: nil)
    root.active.ordered.includes(:children).filter_map do |parent|
      active_children = parent.children.select(&:active?)
                              .sort_by { |c| [c.position, c.name] }

      if product_counts
        # Show all active subcategories, don't filter by product count
        # Only hide the parent if it and all children have 0 products
        parent_total = (product_counts[parent.id] || 0) + active_children.sum { |c| product_counts[c.id] || 0 }
        next if parent_total == 0
      end

      [parent, active_children]
    end
  end

  # ── Instance helpers ──────────────────────────────────────────────

  def root?
    parent_id.nil?
  end

  def leaf?
    children.empty?
  end

  def depth
    root? ? 0 : 1
  end

  def root_category
    root? ? self : parent
  end

  def self_and_children_ids
    return [] unless active? && deleted_at.nil?
    [id] + children.active.pluck(:id)
  end

  def display_name
    root? ? name : "#{parent&.name} > #{name}"
  end

  # ── Attribute Configuration ───────────────────────────────────────
  #
  # attribute_config JSONB structure:
  # {
  #   "product_attributes": {
  #     "base_material": { "label": "Base Material", "required": true, "options": [...] },
  #     "plating":       { "label": "Plating", "required": false, "options": [...] },
  #     ...
  #   },
  #   "variant_attributes": {
  #     "color": { "label": "Color", "required": false, "options": [...] },
  #     "size":  { "label": "Size", "required": false, "options": [...] }
  #   }
  # }
  #
  # Config is set on ROOT categories. Child categories inherit from parent.

  # Returns the effective config (own if root, parent's if child)
  def effective_attribute_config
    cfg = root? ? attribute_config : parent&.attribute_config
    (cfg.presence || {}).with_indifferent_access
  end

  # Product attribute definitions: [{ key:, label:, required:, options: }]
  def product_attribute_definitions
    (effective_attribute_config[:product_attributes] || {}).map do |key, config|
      config.symbolize_keys.merge(key: key.to_s)
    end
  end

  # Variant attribute definitions: [{ key:, label:, required:, options: }]
  def variant_attribute_definitions
    (effective_attribute_config[:variant_attributes] || {}).map do |key, config|
      config.symbolize_keys.merge(key: key.to_s)
    end
  end

  # Options for a specific attribute name
  def options_for(attribute_name)
    all_attrs = effective_attribute_config
    attr_name = attribute_name.to_s

    pa = all_attrs.dig(:product_attributes, attr_name)
    va = all_attrs.dig(:variant_attributes, attr_name)
    (pa || va)&.dig("options") || []
  end

  # Check if category has any attribute config
  def has_attribute_config?
    effective_attribute_config[:product_attributes].present? ||
      effective_attribute_config[:variant_attributes].present?
  end

  # Known product-level column names (these have dedicated DB columns on products)
  PRODUCT_COLUMN_ATTRIBUTES = %w[base_material plating gemstone occasion ideal_for country_of_origin].freeze

  # Known variant-level column names (dedicated DB columns on product_variants)
  VARIANT_COLUMN_ATTRIBUTES = %w[color size].freeze

  private

  def generate_slug
    self.slug = name.parameterize
  end

  def parent_cannot_be_self
    if parent_id.present? && parent_id == id
      errors.add(:parent_id, "can't be the same category")
    end
  end

  def prevent_deep_nesting
    if parent.present? && parent.parent_id.present?
      errors.add(:parent_id, "can't nest more than 2 levels deep (parent > child)")
    end
  end
end
