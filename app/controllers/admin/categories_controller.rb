module Admin
  class CategoriesController < BaseController
    before_action :require_admin_role!
    before_action :set_category, only: [:show, :edit, :update, :destroy, :toggle_status]

    def index
      @categories = Category.includes(:parent, :children).order(:position, :name)
    end

    def show
      @products = @category.products.order(:name)
    end

    def new
      @category = Category.new
    end

    def create
      @category = Category.new(category_params)

      if @category.save
        redirect_to admin_categories_path, notice: "Category created successfully"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @category.update(category_params)
        redirect_to admin_categories_path, notice: "Category updated successfully"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @category.destroy
      redirect_to admin_categories_path, notice: "Category deleted successfully"
    end

    def toggle_status
      @category.update(active: !@category.active?)
      
      respond_to do |format|
        format.html { redirect_to admin_categories_path, notice: "Category #{@category.active? ? 'enabled' : 'disabled'}" }
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@category) }
      end
    end

    private

    def set_category
      @category = Category.find(params[:id])
    end

    def category_params
      permitted = params.require(:category).permit(:name, :slug, :description, :parent_id, :position, :active, :image, :attribute_config)

      # Parse attribute_config from JSON string to hash
      if permitted[:attribute_config].is_a?(String)
        if permitted[:attribute_config].present?
          begin
            permitted[:attribute_config] = JSON.parse(permitted[:attribute_config])
          rescue JSON::ParserError
            # Leave as-is; validation will catch it
            permitted[:attribute_config] = {}
          end
        else
          permitted[:attribute_config] = {}
        end
      end

      permitted
    end
  end
end
