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
      company_params = params.fetch(:store_setting, {}).permit(:gst_number, :company_address, :company_phone, :enable_coupons, :enable_multi_vendor_coupons, :free_delivery_min_amount, :delivery_charge_amount, :youtube_url, :instagram_url, :facebook_url, :twitter_url, :banner_bg_color, :banner_text_color, :banner_accent_color)
      updates.merge!(company_params)

      if @store_setting.update(**updates)
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.append("toasts",
              partial: "shared/toast",
              locals: { message: "Settings saved successfully", variant: :success })
          end
          format.html { redirect_to admin_store_settings_path, notice: "Store settings updated successfully" }
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.append("toasts",
              partial: "shared/toast",
              locals: { message: "Failed to save settings: #{@store_setting.errors.full_messages.join(', ')}", variant: :error })
          end
          format.html { render :show, status: :unprocessable_entity }
        end
      end
    end
  end
end
