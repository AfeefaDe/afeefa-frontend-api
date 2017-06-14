class EntriesController < ApplicationController

  def index
    if (locale = params['locale']).present? && locale.in?(TranslationCacheMetaDatum::SUPPORTED_LOCALES)
      render_data(locale)
    else
      render json: { error: 'locale is not supported' }, status: :unprocessable_entity
    end
  end

  private

  def render_data(locale)
    meta = TranslationCacheMetaDatum.find_by(locale: locale)
    if meta
      unless meta.cache_valid?
        if Rails.env.test?
          FrontendCacheRebuildJob.perform_now(locale)
        else
          FrontendCacheRebuildJob.perform_later(locale)
        end
      end
    else
      content = TranslationCacheMetaDatum.build_translation_data(locale).to_json
      if Rails.env.test?
        FrontendCacheRebuildJob.perform_now(locale, content: content)
      else
        FrontendCacheRebuildJob.perform_later(locale, content: content)
      end
    end

    content ||=
      TranslationCacheMetaDatum.cached_content(locale) ||
        { marketentries: [] }

    render(
      json: content,
      status: :ok,
      language: locale || TranslationCacheMetaDatum::DEFAULT_LOCALE
    )
  end

end
