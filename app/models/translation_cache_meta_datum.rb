class TranslationCacheMetaDatum < ApplicationRecord

  DEFAULT_LOCALE = 'de'
  SUPPORTED_LOCALES = %w(ar de en *es fa fr ku ps ru sq sr ti tr ur)
  CACHE_PATH = Rails.root.join('public', 'cache').to_s

  def self.[](locale, area)
    find_by(locale: locale, area: area)
  end

  def cache_file_path
    File.join(CACHE_PATH, "#{area}-#{locale}.json").to_s
  end

  def cached_file_available?
    File.exists?(cache_file_path)
  end

  def cached_json
    if cached_file_available?
      File.read(cache_file_path)
    end
  end

  def cached_content
    if json = cached_json
      JSON.parse(json)
    end
  end

  def self.build_translation_data(locale, area)
    orgas, events = []
    Orga.transaction do
      Event.transaction do
        TranslationCache.transaction do
          if locale == DEFAULT_LOCALE
            orgas = get_entries(Orga, area)
            events = get_entries(Event, area)
          else
            orgas = get_entries(Orga, area, with_translations: true)
            events = get_entries(Event, area, with_translations: true)
          end
        end
      end
    end
    { marketentries: orgas + events }
  end

  def write_cache_file(content)
    FileUtils.mkdir_p(CACHE_PATH)
    target = cache_file_path
    File.open(target, 'w') do |f|
      f.write(content)
    end
  end

  def cache_valid?
    # check for json file
    return false unless cached_file_available?

    # check updated_at for orgas, events and translation_cache of this locale and area
    entries_for_locale =
      TranslationCache.with_orgas_and_events.where(language: locale)

    update_orgas =
      entries_for_locale.
        where("#{Orga.table_name}.area = ?", area).
        where("#{TranslationCache.table_name}.updated_at >= ? OR #{Orga.table_name}.updated_at >= ?",
          updated_at, updated_at)

    update_events =
      entries_for_locale.
        where("#{Event.table_name}.area = ?", area).
        where("#{TranslationCache.table_name}.updated_at >= ? OR #{Event.table_name}.updated_at >= ?",
          updated_at, updated_at)

    updated_entries =
      update_orgas.or(update_events)

    !updated_entries.exists?
  end

  private

  def self.get_entries(klazz, area, with_translations: false)
    entries =
      klazz.
        includes(:category, :sub_category, :locations, :contact_infos, :parent_orga, parent_orga: :contact_infos).
        where(state: 'active').
        where(area: area)
    if with_translations
      entries = entries.includes(:translation_caches)
    end
    entries
  end

end
