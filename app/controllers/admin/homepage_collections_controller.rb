module Admin
  class HomepageCollectionsController < BaseController
    before_action :require_admin_role!
    before_action :set_collection, only: [:show, :edit, :update, :destroy, :toggle_status]

    def index
      @pagy, @collections = pagy(HomepageCollection.ordered.includes(:items), limit: 20)
    end

    def show
      @items = @collection.items.ordered
    end

    def new
      @collection = HomepageCollection.new
    end

    def create
      @collection = HomepageCollection.new(collection_params)

      if @collection.save
        redirect_to admin_homepage_collection_path(@collection), notice: "Collection created successfully. Now add items to it."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @collection.update(collection_params)
        redirect_to admin_homepage_collection_path(@collection), notice: "Collection updated successfully"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @collection.destroy
      redirect_to admin_homepage_collections_path, notice: "Collection deleted successfully"
    end

    def toggle_status
      @collection.update(active: !@collection.active?)

      respond_to do |format|
        format.html { redirect_to admin_homepage_collections_path, notice: "Collection #{@collection.active? ? 'enabled' : 'disabled'}" }
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@collection) }
      end
    end

    private

    def set_collection
      @collection = HomepageCollection.find(params[:id])
    end

    def collection_params
      params.require(:homepage_collection).permit(:name, :subtitle, :layout_type, :position, :active, :starts_at, :ends_at)
    end
  end
end
