class EntriesController < ApplicationController

  DEFAULT_LOCALE = 'de'
  SUPPORTED_LOCALES = %w(ar en es fa fr ku ps ru sq sr ti tr ur)

  def index
    if !params['locale'].present? || (params['locale'].present? && params['locale'] == DEFAULT_LOCALE)
      orgas = get_entries(Orga)
      events = get_entries(Event)
    else
      if params['locale'].in?(SUPPORTED_LOCALES)
        orgas = get_entries(Orga, with_translations: true)
        events = get_entries(Event, with_translations: true)
      else
        raise 'locale is not supported'
      end
    end

    render(
        json: {
            marketentries: orgas + events
        },
        status: :ok,
        language: params['locale'] || DEFAULT_LOCALE
    )
  end

  private

  def get_entries(klazz, with_translations: false)
    entries =
        klazz.
            includes(:category, :sub_category, :locations, :contact_infos).
            where(state: 'active')
    if with_translations
      entries = entries.includes(:translation_caches)
    end
    entries
  end
end