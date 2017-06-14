class TranslationCacheMetaDatum < ApplicationRecord

  DEFAULT_LOCALE = 'de'
  SUPPORTED_LOCALES = %w(ar de en es fa fr ku ps ru sq sr ti tr ur)
  CACHE_PATH = Rails.root.join('public', 'cache').to_s

  def cache_valid?
    timestamp = TranslationCache.where(language: locale).maximum(:updated_at)
    timestamp.present? && updated_at.present? && timestamp <= updated_at
  end

  def self.[](locale)
    find_by(locale: locale)
  end

  def self.cache_file_path(locale)
    File.join(CACHE_PATH, "#{locale}.json").to_s
  end

  def self.cached_json(locale)
    file = cache_file_path(locale)
    if File.exists?(file)
      File.read(file)
    end
  end

  def self.cached_content(locale)
    if json = cached_json(locale)
      JSON.parse(json)
    end
  end

  def self.cache_valid?(locale)
    (meta = TranslationCacheMetaDatum.find_by(locale: locale)) && meta.cache_valid?
  end

  def self.build_translation_data(locale)
    orgas, events = []
    Orga.transaction do
      Event.transaction do
        TranslationCache.transaction do
          if locale == DEFAULT_LOCALE
            orgas = get_entries(Orga)
            events = get_entries(Event)
          else
            orgas = get_entries(Orga, with_translations: true)
            events = get_entries(Event, with_translations: true)
          end
        end
      end
    end
    { marketentries: orgas + events }
  end

  def self.write_cache_file(locale, content)
    FileUtils.mkdir_p(CACHE_PATH)
    target = File.join(CACHE_PATH, "#{locale}.json")
    File.open(target, 'w') do |f|
      f.write(content)
    end
  end

  private

  def self.get_entries(klazz, with_translations: false)
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
