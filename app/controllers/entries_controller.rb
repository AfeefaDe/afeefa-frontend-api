class EntriesController < ApplicationController
  def include (query)
    query.includes(:category)
    .includes(:sub_category)
    .includes(:locations)
    .includes(:contact_infos)
  end

  def index
    orgas = include(Orga).where("state = 'active'")

    events = include(Event).where("state = 'active'")

    render json: {
      marketentries: orgas + events
    }
  end
end
