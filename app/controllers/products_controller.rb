class ProductsController < ApplicationController
  def index
    @products = Product.all

    case params[:filter]
    when "new"
      @products = Product.newly_added.order(created_at: :desc)
    when "recent"
      @products = Product.recently_updated.order(updated_at: :desc)
    when "sale"
      @products = Product.on_sale.order(updated_at: :desc)
    else
      @products = Product.all.order(created_at: :desc)
    end
  end

  def show
    @product = Product.find(params[:id])
  end
end
