module Admin
  class HomepageSettingsController < BaseController
    before_action :set_settings

    def show
    end

    def edit
    end

    def update
      if @settings.update(settings_params)
        redirect_to admin_homepage_settings_path, notice: "Homepage settings updated successfully"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_settings
      @settings = HomepageSetting.current
    end

    def settings_params
      params.require(:homepage_setting).permit(
        :flash_sale_enabled, :flash_sale_title, :flash_sale_heading,
        :flash_sale_description, :flash_sale_discount, :flash_sale_cta_text,
        :flash_sale_cta_link, :flash_sale_ends_at,
        :promo_banner_enabled, :promo_banner_title, :promo_banner_heading,
        :promo_banner_code, :promo_banner_cta_text, :promo_banner_cta_link,
        :bundle_deals_enabled, :bundle_deals_title, :bundle_deals_heading,
        :bundle_deals_description,
        :gifts_section_enabled, :artisan_section_enabled, :ethnic_section_enabled
      )
    end
  end
end
