module Admin
  class ProductsController < BaseController
    before_action :set_product, only: [:show, :edit, :update, :destroy]

    def index
      @q = params[:q]
      @category_id = params[:category_id]
      @vendor_id = params[:vendor_id]
      @status = params[:status]

      products = vendor_scoped(Product).includes(:category, :variants)
      products = products.search(@q) if @q.present?
      products = products.with_category(@category_id) if @category_id.present?
      if admin_role? && !vendor_context? && @vendor_id.present?
        products = products.where(vendor_id: @vendor_id)
      end

      @product_counts = {
        all: products.count,
        active: products.where(active: true).count,
        draft: products.where(active: false).count,
        featured: products.where(featured: true).count
      }

      products = case @status
      when 'active'
        products.where(active: true)
      when 'draft'
        products.where(active: false)
      when 'featured'
        products.where(featured: true)
      else
        products
      end
      products = products.order(created_at: :desc)

      @pagy, @products = pagy(products, limit: 20)
      @categories = Category.active.ordered

      if admin_role? && !vendor_context?
        @vendors = Vendor.ordered
      end
    end

    def show
      @variants = @product.variants.ordered
      @reviews = @product.reviews.recent.limit(10)
    end

    def new
      @product = Product.new
      @product.variants.build
    end

    def create
      @product = Product.new(product_params)
      @product.vendor = current_vendor if vendor_context?

      if @product.save
        redirect_to admin_product_path(@product), notice: "Product created successfully"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @product.update(product_params)
        redirect_to admin_product_path(@product), notice: "Product updated successfully"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @product.destroy
      redirect_to admin_products_path, notice: "Product deleted successfully"
    end

    private

    def set_product
      @product = vendor_scoped(Product).find(params[:id])
    end

    def product_params
      permitted = [:name, :slug, :description, :short_description, :category_id,
                   :sku, :price, :active, :featured, :hsn_code_id, images: []]
      permitted << :vendor_id if admin_role? && !vendor_context?
      params.require(:product).permit(*permitted)
    end
  end
end
