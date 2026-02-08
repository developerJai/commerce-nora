module Admin
  class HsnCodesController < BaseController
    before_action :require_admin_role!
    before_action :set_hsn_code, only: [:edit, :update, :destroy, :toggle_status]

    def index
      @q = params[:q]
      hsn_codes = HsnCode.all
      hsn_codes = hsn_codes.where("code ILIKE :q OR description ILIKE :q", q: "%#{@q}%") if @q.present?
      hsn_codes = hsn_codes.ordered
      @pagy, @hsn_codes = pagy(hsn_codes, limit: 30)
    end

    def new
      @hsn_code = HsnCode.new
    end

    def create
      @hsn_code = HsnCode.new(hsn_code_params)

      if @hsn_code.save
        redirect_to admin_hsn_codes_path, notice: "HSN Code created successfully"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @hsn_code.update(hsn_code_params)
        redirect_to admin_hsn_codes_path, notice: "HSN Code updated successfully"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @hsn_code.destroy
      redirect_to admin_hsn_codes_path, notice: "HSN Code deleted successfully"
    end

    def toggle_status
      @hsn_code.update(active: !@hsn_code.active?)

      respond_to do |format|
        format.html { redirect_to admin_hsn_codes_path, notice: "HSN Code #{@hsn_code.active? ? 'enabled' : 'disabled'}" }
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@hsn_code) }
      end
    end

    private

    def set_hsn_code
      @hsn_code = HsnCode.find(params[:id])
    end

    def hsn_code_params
      params.require(:hsn_code).permit(:code, :description, :gst_rate, :category_name, :active)
    end
  end
end
