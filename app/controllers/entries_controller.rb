class EntriesController < ApplicationController

  DEFAULT_LOCALE = 'de'
  SUPPORTED_LOCALES = %w(ar de en es fa fr ku ps ru sq sr ti tr ur)

  def index

    if !params['locale'].nil? && params['locale'].in?(SUPPORTED_LOCALES)
      if params['locale'] == DEFAULT_LOCALE
        orgas = include(Orga).where(state: 'active')
        events = include(Event).where(state: 'active')
      else
        orgas = include(Orga).includes(:translation_caches).where(state: 'active')
        events = include(Event).includes(:translation_caches).where(state: 'active')
      end

      render json: {
          marketentries: orgas + events
      },
             status: :ok,
             language: params['locale'] || DEFAULT_LOCALE
    else
      render json: {error: 'locale is not supported'}, status: :unprocessable_entity
    end
  end

  private

  def include (query)
    query.includes(:category, :sub_category, :locations, :contact_infos)
  end
end
