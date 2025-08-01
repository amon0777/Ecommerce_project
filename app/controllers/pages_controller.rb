class PagesController < ApplicationController
  def show
     @page = Page.find_by!(slug: params[:slug])
    render params[:slug]
  end
  
  def home
  end

  def about
  end

  def contact
  end
end
