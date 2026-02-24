module Admin
  class StoreSettingsController < BaseController
    before_action :require_admin_role!

    def show
      @store_setting = StoreSetting.instance
    end

    def update
      @store_setting = StoreSetting.instance

      # Convert checkbox params ("1"/"0") to boolean hash for filters
      filter_config = {}
      StoreSetting::FILTER_KEYS.each do |key|
        filter_config[key] = params.dig(:store_setting, :filter_config, key) == "1"
      end

      # Convert checkbox params for payment methods
      payment_config = {}
      StoreSetting::PAYMENT_KEYS.each do |key|
        payment_config[key] = params.dig(:store_setting, :payment_config, key) == "1"
      end

      # Update company details and coupon setting
      company_params = params.require(:store_setting).permit(:gst_number, :company_address, :company_phone, :enable_coupons)

      if @store_setting.update(filter_config: filter_config, payment_config: payment_config, **company_params)
        redirect_to admin_store_settings_path, notice: "Store settings updated successfully"
      else
        render :show, status: :unprocessable_entity
      end
    end
  end
end
