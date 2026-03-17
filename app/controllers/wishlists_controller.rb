class WishlistsController < ApplicationController
  before_action :require_customer

  def index
    @wishlist_items = current_customer.wishlist_items.includes(product: [{ variants: { image_attachment: :blob } }, { images_attachments: :blob }], product_variant: { image_attachment: :blob }).order(created_at: :desc)
  end

  def create
    product = Product.active.find(params[:product_id])
    @product = product
    @icon_only = params[:icon_only].to_s == "true"
    @variant_id = params[:variant_id].presence

    # Find or initialize with both product and variant
    wishlist_item = if @variant_id.present?
      current_customer.wishlist_items.find_or_initialize_by(product: product, product_variant_id: @variant_id)
    else
      current_customer.wishlist_items.find_or_initialize_by(product: product, product_variant_id: nil)
    end

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
    # Find by product_id and optionally variant_id
    wishlist_query = current_customer.wishlist_items.where(product_id: params[:product_id])
    wishlist_query = wishlist_query.where(product_variant_id: params[:variant_id]) if params[:variant_id].present?
    
    wishlist_item = wishlist_query.first
    
    # If no specific variant match found, try without variant (fallback for legacy items)
    wishlist_item ||= current_customer.wishlist_items.find_by!(product_id: params[:product_id]) unless wishlist_item
    
    raise ActiveRecord::RecordNotFound unless wishlist_item
    
    product = wishlist_item.product
    @product = product
    @icon_only = params[:icon_only].to_s == "true"
    @variant_id = wishlist_item.product_variant_id
    
    wishlist_item.destroy
    current_customer.wishlist_items.reload
    @wishlist_items = current_customer.wishlist_items
    
    respond_to do |format|
      format.html { redirect_back(fallback_location: wishlists_path, notice: "Product removed from wishlist") }
      format.turbo_stream
    end
  end

  def clear
    current_customer.wishlist_items.destroy_all
    current_customer.wishlist_items.reload
    
    respond_to do |format|
      format.html { redirect_to wishlists_path, notice: "Wishlist cleared" }
      format.turbo_stream
    end
  end
end
