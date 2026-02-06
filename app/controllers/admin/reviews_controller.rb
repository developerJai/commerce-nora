module Admin
  class ReviewsController < BaseController
    before_action :set_review, only: [:show, :edit, :update, :destroy, :approve, :reject, :respond]

    def index
      @status = params[:status]
      reviews = Review.includes(:product, :customer).recent
      reviews = reviews.approved if @status == 'approved'
      reviews = reviews.pending if @status == 'pending'
      @pagy, @reviews = pagy(reviews, limit: 20)
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
      @review = Review.find(params[:id])
    end

    def review_params
      params.require(:review).permit(:rating, :title, :body, :approved, :admin_response)
    end
  end
end
