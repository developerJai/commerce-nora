class CategoriesController < ApplicationController
  def show
    category = Category.active.find_by!(slug: params[:slug])

    # For root categories, include all child category IDs so products from
    # subcategories also appear. For leaf categories, just use their own ID.
    category_ids = category.self_and_children_ids

    redirect_to products_path(category_ids: category_ids, **params.except(:slug, :controller, :action).permit!)
  end
end
