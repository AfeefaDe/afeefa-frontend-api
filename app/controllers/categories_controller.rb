class CategoriesController < ApplicationController

  private

  def render_data(_locale, area)
    render json: { categories: Category.where(area: area) }
  end

end
