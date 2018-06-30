class NavigationController < ApplicationController

  private

  def render_data(_locale, area)
    cache_file_path = File.join(CacheBuilder::CACHE_PATH, "navigation-#{area}.json").to_s
    send_file cache_file_path, type: 'application/json', disposition: 'inline'
  end

end
