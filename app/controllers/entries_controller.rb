class EntriesController < ApplicationController

  def index
    locale = params['locale'] || TranslationCacheMetaDatum::DEFAULT_LOCALE

    if locale.in?(TranslationCacheMetaDatum::SUPPORTED_LOCALES)
      render_data(locale)
    else
      raise 'locale is not supported'
    end
  end

  private

  def render_data(locale)
    meta = TranslationCacheMetaDatum.find_by(locale: locale)
    if meta && meta.updated_at > 10.minutes.ago && !params[:force_refresh]
      unless meta.cache_valid?
        if Rails.env.test?
          FrontendCacheRebuildJob.perform_now(locale)
        else
          FrontendCacheRebuildJob.perform_later(locale)
        end
      end
    else
      content = TranslationCacheMetaDatum.build_translation_data(locale).to_json
      FrontendCacheRebuildJob.perform_now(locale, content: content)
    end

    content ||=
      TranslationCacheMetaDatum[locale].cached_content ||
        { marketentries: [] }

    render(
      json: content,
      status: :ok,
      language: locale || TranslationCacheMetaDatum::DEFAULT_LOCALE
    )
  end

  private

  def get_entries(klazz, with_translations: false)
    entries =
        klazz.
            includes(:category, :sub_category, :locations, :contact_infos, :parent_orga).
            where(state: 'active')
    if with_translations
      entries = entries.includes(:translation_caches)
    end
    entries
  end
end
