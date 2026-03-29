module Admin
  class MobileAppSettingsController < BaseController
    before_action :require_admin_role!

    def show
      @store_setting = StoreSetting.instance
    end

    def update
      @store_setting = StoreSetting.instance
      mobile_params = params.require(:store_setting).permit(
        :mobile_apps_enabled, :ios_app_url, :android_app_url,
        :mobile_app_section_title, :mobile_app_section_subtitle,
        :smart_banner_title, :smart_banner_subtitle,
        :ios_team_id, :ios_bundle_id, :android_package_name, :android_sha256_fingerprint
      )

      if @store_setting.update(mobile_params)
        redirect_to admin_mobile_app_settings_path, notice: "Mobile app settings updated successfully"
      else
        render :show, status: :unprocessable_entity
      end
    end
  end
end
