class HomepageCollection < ApplicationRecord
  include SoftDeletable

  has_many :items, class_name: "HomepageCollectionItem", dependent: :destroy

  validates :name, presence: true
  validates :layout_type, presence: true, inclusion: {
    in: %w[grid_4 grid_3 grid_2 bento asymmetric],
    message: "%{value} is not a valid layout type"
  }

  scope :active, -> { where(active: true) }
  scope :current, -> {
    now = Time.current
    where("(starts_at IS NULL OR starts_at <= ?) AND (ends_at IS NULL OR ends_at >= ?)", now, now)
  }
  scope :ordered, -> { order(:position, :created_at) }
  scope :visible, -> { active.current.ordered }

  LAYOUT_TYPES = {
    "grid_4" => "4-Column Grid",
    "grid_3" => "3-Column Grid",
    "grid_2" => "2-Column Grid",
    "bento" => "Bento Grid (Featured Left + Grid Right)",
    "asymmetric" => "Asymmetric (Large Left + Stacked Right)"
  }.freeze

  def visible?
    active? && within_date_range?
  end

  def within_date_range?
    now = Time.current
    (starts_at.nil? || starts_at <= now) && (ends_at.nil? || ends_at >= now)
  end

  def layout_label
    LAYOUT_TYPES[layout_type] || layout_type.humanize
  end

  def min_items_for_layout
    case layout_type
    when "grid_4" then 4
    when "grid_3" then 3
    when "grid_2" then 2
    when "bento" then 5
    when "asymmetric" then 3
    else 1
    end
  end

  # Returns recommended image dimensions per layout type
  # [position_index] => { width:, height:, label: }
  LAYOUT_DIMENSIONS = {
    "grid_4" => {
      default: { width: 800, height: 1000, label: "All items", ratio: "3:4 portrait" }
    },
    "grid_3" => {
      default: { width: 800, height: 1000, label: "All items", ratio: "4:5 portrait" }
    },
    "grid_2" => {
      default: { width: 1200, height: 700, label: "All items", ratio: "16:9 landscape" }
    },
    "bento" => {
      0 => { width: 800, height: 1000, label: "Hero (left, large)", ratio: "4:5 portrait" },
      default: { width: 600, height: 500, label: "Grid items (right)", ratio: "6:5 landscape" }
    },
    "asymmetric" => {
      0 => { width: 800, height: 1000, label: "Hero (left, large)", ratio: "4:5 portrait" },
      default: { width: 1000, height: 500, label: "Stacked items (right)", ratio: "2:1 landscape" }
    }
  }.freeze

  def dimension_for_position(position_index)
    layout = LAYOUT_DIMENSIONS[layout_type] || {}
    layout[position_index] || layout[:default] || { width: 800, height: 800, label: "Standard", ratio: "1:1 square" }
  end
end
