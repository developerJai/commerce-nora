module Admin
  class StoreSettingsController < BaseController
    before_action :require_admin_role!

    def show
      @store_setting = StoreSetting.instance
    end

    def update
      @store_setting = StoreSetting.instance

      # Convert checkbox params ("1"/"0") to boolean hash
      filter_config = {}
      StoreSetting::FILTER_KEYS.each do |key|
        filter_config[key] = params.dig(:store_setting, :filter_config, key) == "1"
      end

      if @store_setting.update(filter_config: filter_config)
        redirect_to admin_store_settings_path, notice: "Filter settings updated successfully"
      else
        render :show, status: :unprocessable_entity
      end
    end
  end
end
