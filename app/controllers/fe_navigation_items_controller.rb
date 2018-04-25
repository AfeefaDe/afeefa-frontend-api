class FeNavigationItemsController < ApplicationController

  private

  def render_data(_locale, area)
    render json: { fe_navigation_items: FeNavigation.where(area: area).first.navigation_items.where(parent: nil) }
  end

end
