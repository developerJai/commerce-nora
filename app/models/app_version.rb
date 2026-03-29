class AppVersion < ApplicationRecord
  PLATFORMS = %w[ios android].freeze

  validates :platform, presence: true, inclusion: { in: PLATFORMS }
  validates :version_number, presence: true,
            format: { with: /\A\d+\.\d+\.\d+\z/, message: "must be semantic versioning (e.g. 1.2.0)" },
            uniqueness: { scope: :platform, message: "already exists for this platform" }

  scope :ios, -> { where(platform: "ios") }
  scope :android, -> { where(platform: "android") }
  scope :active, -> { where(active: true) }
  scope :forced, -> { where(force_update: true) }
  scope :by_version, -> { order(Arel.sql("string_to_array(version_number, '.')::int[] DESC")) }

  # Returns the update status for a given platform + client version.
  #
  # If ANY active version between client_version (exclusive) and latest (inclusive)
  # has force_update: true, the response will flag a forced update. This ensures
  # users can never skip a breaking change even if later versions are optional.
  def self.check_update(platform, client_version)
    return no_update_response if client_version.blank?

    versions = active.where(platform: platform).to_a
    return no_update_response if versions.empty?

    client_gem = gem_version(client_version)
    return no_update_response unless client_gem

    # Sort ascending and find newer versions
    sorted = versions.sort_by { |v| gem_version(v.version_number) || Gem::Version.new("0") }
    latest = sorted.last
    latest_gem = gem_version(latest.version_number)

    return no_update_response if latest_gem.nil? || latest_gem <= client_gem

    # Check if any version between client and latest (exclusive of client) is forced
    newer_versions = sorted.select { |v| (gv = gem_version(v.version_number)) && gv > client_gem }
    force = newer_versions.any?(&:force_update?)

    store_url = latest.store_url.presence || default_store_url(platform)

    {
      update_available: true,
      force_update: force,
      latest_version: latest.version_number,
      release_notes: latest.release_notes,
      store_url: store_url
    }
  end

  def self.no_update_response
    { update_available: false, force_update: false }
  end

  def self.gem_version(str)
    Gem::Version.new(str)
  rescue ArgumentError
    nil
  end

  def self.default_store_url(platform)
    setting = StoreSetting.instance
    platform == "ios" ? setting.ios_app_url : setting.android_app_url
  end
end
