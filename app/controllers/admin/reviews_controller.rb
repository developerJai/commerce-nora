module Admin
  class ReviewsController < BaseController
    before_action :set_review, only: [:show, :edit, :update, :destroy, :approve, :reject, :respond]

    def index
      @status = params[:status]
      @vendor_id = params[:vendor_id]
      reviews = if vendor_context?
        Review.joins(:product).where(products: { vendor_id: current_vendor.id })
      else
        Review.all
      end

      if admin_role? && !vendor_context? && @vendor_id.present?
        reviews = reviews.joins(:product).where(products: { vendor_id: @vendor_id })
      end

      @review_counts = {
        all: reviews.count,
        pending: reviews.pending.count,
        approved: reviews.approved.count
      }

      reviews = reviews.includes(:product, :customer).recent
      reviews = reviews.approved if @status == 'approved'
      reviews = reviews.pending if @status == 'pending'
      @pagy, @reviews = pagy(reviews, limit: 20)

      if admin_role? && !vendor_context?
        @vendors = Vendor.ordered
      end
    end

    def show
    end

    def edit
    end

    def update
      if @review.update(review_params)
        redirect_to admin_reviews_path, notice: "Review updated successfully"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @review.destroy
      redirect_to admin_reviews_path, notice: "Review deleted successfully"
    end

    def approve
      @review.approve!
      redirect_to admin_reviews_path, notice: "Review approved"
    end

    def reject
      @review.reject!
      redirect_to admin_reviews_path, notice: "Review rejected"
    end

    def respond
      @review.update(admin_response: params[:admin_response])
      redirect_to admin_review_path(@review), notice: "Response saved"
    end

    private

    def set_review
      @review = if vendor_context?
        Review.joins(:product).where(products: { vendor_id: current_vendor.id }).find(params[:id])
      else
        Review.find(params[:id])
      end
    end

    def review_params
      params.require(:review).permit(:rating, :title, :body, :approved, :admin_response)
    end
  end
end
