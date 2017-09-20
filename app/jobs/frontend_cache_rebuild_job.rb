class FrontendCacheRebuildJob < ApplicationJob
  queue_as :default

  def logger
    @logger ||=
      if log_file = Rails.root.join('log', "#{self.class.to_s.underscore}.log")
        Logger.new(log_file)
      else
        Rails.logger
      end
  end

  def perform(locale, area)
    TranslationCacheMetaDatum.transaction do
      meta = TranslationCacheMetaDatum.find_or_create_by(locale: locale, area: area)
      unless meta
        logger.info "#{locale} is not supported yet."
        return
      end
      if meta.locked_at?
        logger.info "#{locale} cache is already in progress, so skip this job."
        return
      else
        meta.update(locked_at: Time.current)
        logger.info "start rebuild of #{locale} cache."
        content = TranslationCacheMetaDatum.build_translation_data(locale, area).to_json(language: locale)
        meta.write_cache_file(content)
        logger.info "finished rebuild of #{locale} cache."
        meta.update(locked_at: nil, updated_at: Time.current)
      end
    end
  end
end
