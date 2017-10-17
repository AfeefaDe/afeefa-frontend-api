class CacheBuilder

  CACHE_PATH = Rails.root.join(Settings.cache.path).to_s

  def build_all
    Translation::AREAS.each do |area|
      build_area(area)
    end
  end

  def translate_entry(type, id, locale)
    entry = type == 'orga' ? get_entry(Orga, id, locale) : get_entry(Event, id, locale)
    if entry
      json = read_cache_file(entry.area, locale)
      jsonEntries = json['marketentries']

      jsonEntries.map! do |jsonEntry|
        if jsonEntry['id'] == id
          entry
        else
          jsonEntry
        end
      end

      jsonEntries = jsonEntries.to_json(language: locale)
      content = "{\"marketentries\":#{jsonEntries}}"
      write_cache_file(entry.area, locale, content)
    end
  end

  def update_entry(type, id)
    locales = [Translation::DEFAULT_LOCALE] + Translation::TRANSLATABLE_LOCALES
    locales.each do |locale|
      translate_entry(type, id, locale)
    end
  end

  def remove_entry(area, type, id)
    locales = [Translation::DEFAULT_LOCALE] + Translation::TRANSLATABLE_LOCALES
    locales.each do |locale|
      json = read_cache_file(area, locale)
      jsonEntries = json['marketentries']

      jsonEntries.select! do |jsonEntry|
        if jsonEntry['entryType'] == type.capitalize && jsonEntry['id'] == id
          false
        else
          true
        end
      end

      jsonEntries = jsonEntries.to_json(language: locale)
      content = "{\"marketentries\":#{jsonEntries}}"
      write_cache_file(area, locale, content)
    end
  end

  def purge
    FileUtils.rm_rf(Dir.glob("#{CACHE_PATH}/*"))
  end

  private

  def read_cache_file(area, locale)
    cache_file_path = File.join(CACHE_PATH, "#{area}-#{locale}.json").to_s
    file = File.read(cache_file_path)
    JSON.parse(file)
  end

  def write_cache_file(area, locale, content)
    cache_file_path = File.join(CACHE_PATH, "#{area}-#{locale}.json").to_s
    File.open(cache_file_path, 'w') do |f|
      f.write(content)
    end
  end

  def build_area(area)
    locales = [Translation::DEFAULT_LOCALE] + Translation::TRANSLATABLE_LOCALES
    locales.each do |locale|
      build_locale(area, locale)
    end
  end

  def build_locale(area, locale)
    orgas = get_entries(Orga, area, locale)
    events = get_entries(Event, area, locale)
    content = { marketentries: orgas + events }.to_json(language: locale)
    write_cache_file(area, locale, content)
  end

  def get_entries(model_class, area, locale)
    entries = model_class.
      includes(:category, :sub_category, :locations, :contact_infos, :parent_orga, parent_orga: :contact_infos).
      where(state: 'active').
      where(area: area)
    if locale != Translation::DEFAULT_LOCALE
      entries = entries.includes(:translation_caches)
    end
    entries
  end

  def get_entry(model_class, id, locale)
    entries = model_class.
      includes(:category, :sub_category, :locations, :contact_infos, :parent_orga, parent_orga: :contact_infos).
      where(id: id).
      where(state: 'active')
    if locale != Translation::DEFAULT_LOCALE
      entries = entries.includes(:translation_caches)
    end
    entries.first
  end

end