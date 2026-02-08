module Admin
  class HomepageCollectionItemsController < BaseController
    before_action :require_admin_role!
    before_action :set_collection
    before_action :set_item, only: [:edit, :update, :destroy]

    def new
      @item = @collection.items.new
    end

    def create
      @item = @collection.items.new(item_params)

      if @item.save
        redirect_to admin_homepage_collection_path(@collection), notice: "Item added successfully"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @item.update(item_params)
        redirect_to admin_homepage_collection_path(@collection), notice: "Item updated successfully"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @item.destroy
      redirect_to admin_homepage_collection_path(@collection), notice: "Item removed successfully"
    end

    private

    def set_collection
      @collection = HomepageCollection.find(params[:homepage_collection_id])
    end

    def set_item
      @item = @collection.items.find(params[:id])
    end

    def item_params
      params.require(:homepage_collection_item).permit(:title, :subtitle, :badge_text, :link_url, :position, :overlay_position, :image)
    end
  end
end
