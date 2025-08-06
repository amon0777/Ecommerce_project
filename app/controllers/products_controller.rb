class ProductsController < ApplicationController
  def index
    @products = Product.all

    # Keyword Search
    if params[:keyword].present?
      keyword = params[:keyword].downcase
      @products = @products.where("LOWER(name) LIKE ? OR LOWER(description) LIKE ?", "%#{keyword}%", "%#{keyword}%")
    end

    # Category Filter
    if params[:category_id].present?
      @products = @products.where(category_id: params[:category_id])
    end

    # Filter by status
    case params[:filter]
    when "new"
      @products = @products.newly_added.order(created_at: :desc)
    when "recent"
      @products = @products.recently_updated.order(updated_at: :desc)
    when "sale"
      @products = @products.on_sale.order(updated_at: :desc)
    else
      @products = @products.order(created_at: :desc)
    end

    @products = @products.page(params[:page]) # Kaminari pagination
  end

  def show
    @product = Product.find(params[:id])
  end
end
