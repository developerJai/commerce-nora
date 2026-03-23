module Admin
  class StoreSettingsController < BaseController
    before_action :require_admin_role!

    def show
      @store_setting = StoreSetting.instance
      @categories    = Category.includes(:children).order(:position, :name)
    end

    def update
      @store_setting = StoreSetting.instance
      updates = {}

      # Only update filter_config when those params were submitted (filter form)
      if params.dig(:store_setting, :filter_config).present?
        filter_config = {}
        StoreSetting::FILTER_KEYS.each do |key|
          filter_config[key] = params.dig(:store_setting, :filter_config, key) == "1"
        end
        updates[:filter_config] = filter_config
      end

      # Only update payment_config when those params were submitted (main settings form)
      if params.dig(:store_setting, :payment_config).present?
        payment_config = {}
        StoreSetting::PAYMENT_KEYS.each do |key|
          payment_config[key] = params.dig(:store_setting, :payment_config, key) == "1"
        end
        updates[:payment_config] = payment_config
      end

      # Company details, coupon, delivery, and social media — permit individually so missing keys are safely ignored
      company_params = params.fetch(:store_setting, {}).permit(:gst_number, :company_address, :company_phone, :enable_coupons, :free_delivery_min_amount, :delivery_charge_amount, :youtube_url, :instagram_url, :facebook_url, :twitter_url)
      updates.merge!(company_params)

      if @store_setting.update(**updates)
        redirect_to admin_store_settings_path, notice: "Store settings updated successfully"
      else
        render :show, status: :unprocessable_entity
      end
    end
  end
end
