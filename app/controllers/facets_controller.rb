class FacetsController < ApplicationController

  private

  def render_data(_locale, _area)
    cache_file_path = File.join(CacheBuilder::CACHE_PATH, "facets.json").to_s
    send_file cache_file_path, type: 'application/json', disposition: 'inline'
  end

end
