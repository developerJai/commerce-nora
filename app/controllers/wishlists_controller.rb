class WishlistsController < ApplicationController
  before_action :require_customer

  def index
    @wishlist_items = current_customer.wishlist_items.includes(:product).order(created_at: :desc)
  end

  def create
    product = Product.active.find(params[:product_id])
    @product = product
    @icon_only = params[:icon_only].to_s == "true"
    
    wishlist_item = current_customer.wishlist_items.find_or_initialize_by(product: product)
    
    if wishlist_item.save
      respond_to do |format|
        format.html { redirect_back(fallback_location: product_path(product), notice: "Product added to wishlist") }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_back(fallback_location: product_path(product), alert: "Could not add product to wishlist") }
        format.turbo_stream { head :unprocessable_entity }
      end
    end
  end

  def destroy
    wishlist_item = current_customer.wishlist_items.find(params[:id])
    product = wishlist_item.product
    @product = product
    @icon_only = params[:icon_only].to_s == "true"
    
    wishlist_item.destroy
    
    respond_to do |format|
      format.html { redirect_back(fallback_location: wishlists_path, notice: "Product removed from wishlist") }
      format.turbo_stream
    end
  end

  def clear
    current_customer.wishlist_items.destroy_all
    
    respond_to do |format|
      format.html { redirect_to wishlists_path, notice: "Wishlist cleared" }
      format.turbo_stream
    end
  end
end
