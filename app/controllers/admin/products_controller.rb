module Admin
  class ProductsController < BaseController
    before_action :set_product, only: [:show, :edit, :update, :destroy]

    def index
      @q = params[:q]
      @category_id = params[:category_id]

      products = Product.includes(:category, :variants)
      products = products.search(@q) if @q.present?
      products = products.with_category(@category_id) if @category_id.present?
      products = products.order(created_at: :desc)

      @pagy, @products = pagy(products, limit: 20)
      @categories = Category.active.ordered
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
      @product = Product.find(params[:id])
    end

    def product_params
      params.require(:product).permit(
        :name, :slug, :description, :short_description, :category_id,
        :sku, :price, :active, :featured, images: []
      )
    end
  end
end
