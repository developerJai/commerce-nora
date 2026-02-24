module Admin
  class PlatformFeeConfigsController < BaseController
    before_action :require_admin_role!
    before_action :set_config

    def show
    end

    def edit
    end

    def update
      if @config.update(config_params)
        redirect_to admin_platform_fee_config_path, notice: "Fee configuration updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_config
      @config = PlatformFeeConfig.current
    end

    def config_params
      params.require(:platform_fee_config).permit(
        :platform_commission_percent,
        :gateway_fee_percent,
        :gateway_gst_percent,
        :minimum_payout_amount,
        :maximum_payout_amount,
        :absorb_fees
      )
    end
  end
end
