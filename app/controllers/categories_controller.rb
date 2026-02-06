class CategoriesController < ApplicationController
  def show
    category = Category.active.find_by!(slug: params[:slug])
    
    # Redirect to products index with category_ids parameter
    redirect_to products_path(category_ids: [category.id], **params.except(:slug, :controller, :action).permit!)
  end
end
