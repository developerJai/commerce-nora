class OrderReviewsController < ApplicationController
  before_action :require_customer
  before_action :set_order
  before_action :check_can_review

  def new
    @product = Product.find(params[:product_id])
    @review = @order.reviews.build(product: @product, customer: current_customer)
  end

  def create
    @product = Product.find(params[:review][:product_id])
    @review = @order.reviews.build(review_params)
    @review.customer = current_customer
    @review.product = @product

    if @review.save
      redirect_to order_path(@order), notice: "Thank you for your review!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_order
    @order = current_customer.orders.find_by!(order_number: params[:order_order_number])
  end

  def check_can_review
    unless @order.can_review?
      redirect_to order_path(@order), alert: "You can only review delivered orders"
    end
  end

  def review_params
    params.require(:review).permit(:rating, :title, :body)
  end
end
