module Admin
  class BundleDealsController < BaseController
    before_action :set_bundle_deal, only: [ :show, :edit, :update, :destroy ]

    def index
      @bundle_deals = BundleDeal.ordered
    end

    def show
    end

    def new
      @bundle_deal = BundleDeal.new
    end

    def create
      @bundle_deal = BundleDeal.new(bundle_deal_params)

      if @bundle_deal.save
        redirect_to admin_bundle_deals_path, notice: "Bundle deal created successfully"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @bundle_deal.update(bundle_deal_params)
        redirect_to admin_bundle_deals_path, notice: "Bundle deal updated successfully"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @bundle_deal.destroy
      redirect_to admin_bundle_deals_path, notice: "Bundle deal deleted successfully"
    end

    private

    def set_bundle_deal
      @bundle_deal = BundleDeal.find(params[:id])
    end

    def bundle_deal_params
      params.require(:bundle_deal).permit(
        :title, :description, :original_price, :discounted_price,
        :discount_percentage, :image, :cta_text, :cta_link,
        :position, :active,
        bundle_deal_items_attributes: [ :id, :product_id, :quantity, :position, :_destroy ]
      )
    end
  end
end
