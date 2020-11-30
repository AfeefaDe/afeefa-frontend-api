class CacheBuilder

  CACHE_PATH = Rails.root.join(Settings.cache.path).to_s

  def build_all
    # build factest
    build_facets
    # build navigation
    build_navigations
    # build entries
    build_entries
    # build translations
    translate_all_areas
  end

  def translate_entry(type, id, locale)
    entry = entry_type_to_entry(type, id)

    if entry
      translation_cache = entry.translation_caches.find_by(language: locale)
      entry_translation = get_entry_translation(entry, translation_cache)

      if entry.respond_to?(:area) # orga, offer, event, navigation_item
        update_entry_translation_file(entry.area, locale, type, id, entry_translation)
      else # facet_item is valid for all areas
        Translation::AREAS.each do |area|
          update_entry_translation_file(area, locale, type, id, entry_translation)
        end
      end
    end
  end

  def update_entry(type, id)
    entry = entry_type_to_entry(type, id)

    if entry
      updated = true
      case type
      when 'orga', 'event', 'offer'
        active = (entry.respond_to?(:state) && entry.state == 'active') ||
          (entry.respond_to?(:active) && entry.active)
        if active
          update_entry_file(type, id, entry)
        else
          remove_entry_from_file(entry.area, type, id)
          remove_entry_from_translation_files(entry.area, type, id)
          updated = false
        end
      when 'facet_item'
        build_facets
      when 'fe_navigation_item'
        build_navigation(entry.area)
      end

      if updated
        locales = [Translation::DEFAULT_LOCALE] + Translation::TRANSLATABLE_LOCALES
        locales.each do |locale|
          translate_entry(type, id, locale) # de title might be changed
        end
      end
    end
  end

  def remove_entry(area, type, id) # need to pass area since entry already removed from db
    case type
    when 'orga', 'event', 'offer'
      remove_entry_from_file(area, type, id)
    when 'facet_item'
      build_facets
    when 'fe_navigation_item'
      build_navigation(area)
    end

    remove_entry_from_translation_files(area, type, id)
  end

  def purge
    FileUtils.rm_rf(Dir.glob("#{CACHE_PATH}/*"))
  end

  def translate_all_areas
    Translation::AREAS.each do |area|
      translate_area(area)
    end
  end

  def translate_area(area)
    locales = [Translation::DEFAULT_LOCALE] + Translation::TRANSLATABLE_LOCALES
    locales.each do |locale|
      translate_language_for_area(area, locale)
    end
  end

  def translate_language_for_area(area, locale)
    translations = {}

    translations['orgas'] = get_entry_translations(Orga, area, locale)
    translations['offers'] = get_entry_translations(DataModules::Offer::Offer, area, locale)
    translations['events'] = get_entry_translations(Event, area, locale)
    translations['facet_items'] = get_facet_item_translations(locale)
    translations['navigation_items'] = get_navigation_item_translations(area, locale)

    content = translations.to_json
    cache_file_path = File.join(CACHE_PATH, "lang-#{locale}-#{area}.json").to_s
    write_cache_file(cache_file_path, content)
  end

  def build_entries_for_area(area)
    content = {
      orgas: get_entries(Orga, area),
      offers: get_entries(DataModules::Offer::Offer, area),
      events: get_entries(Event, area)
    }.to_json
    cache_file_path = File.join(CACHE_PATH, "entries-#{area}.json").to_s
    write_cache_file(cache_file_path, content)
  end

  private

  def get_entry_translations(model_class, area, locale)
    translations = []

    entries = get_entries_with_translations(model_class, area)
    entries.each do |entry|
      translation_cache = entry.translation_caches.find {|t| t.language == locale}
      translations << get_entry_translation(entry, translation_cache)
    end

    translations
  end

  def get_entry_translation(entry, translation_cache)
    entry_translation = {
      id: entry.id,
      title: translation_cache && translation_cache.title || entry.title || ''
    }
    if entry.respond_to?(:short_description)
      entry_translation['short_description'] = translation_cache && translation_cache.short_description || entry.short_description || ''
    end
    if entry.respond_to?(:description)
      entry_translation['description'] = translation_cache && translation_cache.description || entry.description || ''
    end
    entry_translation
  end

  def update_entry_translation_file(area, locale, type, id, entry_translation)
    cache_file_path = File.join(CACHE_PATH, "lang-#{locale}-#{area}.json").to_s
    json = read_cache_file(cache_file_path)

    if type == 'fe_navigation_item'
      type = 'navigation_item'
    end

    entry_found = false
    if json[type + 's']
      json[type + 's'].map! do |json_entry|
        if json_entry['id'].to_s == id.to_s
          entry_found = true
          entry_translation
        else
          json_entry
        end
      end
    end

    if !entry_found
      json[type + 's'] << entry_translation
    end

    content = json.to_json
    cache_file_path = File.join(CACHE_PATH, "lang-#{locale}-#{area}.json").to_s
    write_cache_file(cache_file_path, content)
  end

  def update_entry_file(type, id, entry)
    cache_file_path = File.join(CACHE_PATH, "entries-#{entry.area}.json").to_s
    json = read_cache_file(cache_file_path)

    if type == 'fe_navigation_item'
      type = 'navigation_item'
    end

    entry_found = false
    json[type + 's'].map! do |json_entry|
      if json_entry['id'].to_s == id.to_s
        entry_found = true
        entry.as_json
      else
        json_entry
      end
    end

    if !entry_found
      json[type + 's'] << entry.as_json
    end

    content = json.to_json
    write_cache_file(cache_file_path, content)
  end

  def build_entries
    Translation::AREAS.each do |area|
      build_entries_for_area(area)
    end
  end

  def remove_entry_from_file(area, type, id)
    # remove from entries file
    cache_file_path = File.join(CACHE_PATH, "entries-#{area}.json").to_s
    json = read_cache_file(cache_file_path)

    if type == 'fe_navigation_item'
      type = 'navigation_item'
    end

    json[type + 's'].select! do |json_entry|
      if json_entry['id'].to_s == id.to_s
        false
      else
        true
      end
    end

    content = json.to_json
    write_cache_file(cache_file_path, content)
  end

  def remove_entry_from_translation_files(area, type, id)
    locales = [Translation::DEFAULT_LOCALE] + Translation::TRANSLATABLE_LOCALES
    locales.each do |locale|
      cache_file_path = File.join(CACHE_PATH, "lang-#{locale}-#{area}.json").to_s
      json = read_cache_file(cache_file_path)

      if type == 'fe_navigation_item'
        type = 'navigation_item'
      end

      json[type + 's'].select! do |json_entry|
        if json_entry['id'].to_s == id.to_s
          false
        else
          true
        end
      end

      content = json.to_json
      write_cache_file(cache_file_path, content)
    end
  end

  def build_facets
    facets = DataPlugins::Facet::Facet.includes(:facet_items, { facet_items: :sub_items }).all

    content = facets.to_json
    cache_file_path = File.join(CACHE_PATH, "facets.json").to_s
    write_cache_file(cache_file_path, content)
  end

  def get_facet_item_translations(locale)
    translations = []

    facet_items = DataPlugins::Facet::FacetItem.includes(:translation_caches).all
    facet_items.each do |facet_item|
      translation_cache = facet_item.translation_caches.find {|t| t.language == locale}
      translations << get_entry_translation(facet_item, translation_cache)
    end
    translations
  end

  def build_navigations
    Translation::AREAS.each do |area|
      build_navigation(area)
    end
  end

  def build_navigation(area)
    navigation_items = DataModules::FeNavigation::FeNavigationItem.by_area(area).includes(:sub_items).where(parent_id: nil).all

    content = navigation_items.to_json
    cache_file_path = File.join(CACHE_PATH, "navigation-#{area}.json").to_s
    write_cache_file(cache_file_path, content)
  end

  def get_navigation_item_translations(area, locale)
    translations = []

    navigation_items = DataModules::FeNavigation::FeNavigationItem.includes(:translation_caches).by_area(area).all
    navigation_items.each do |navigation_item|
      translation_cache = navigation_item.translation_caches.find {|t| t.language == locale}
      translations << get_entry_translation(navigation_item, translation_cache)
    end

    translations
  end

  def entry_type_to_entry(type, id)
    entry = nil
    case type
    when 'orga'
      entry = Orga.find_by(id: id)
    when 'event'
      entry = Event.find_by(id: id)
    when 'offer'
      entry = DataModules::Offer::Offer.find_by(id: id)
    when 'facet_item'
      entry = DataPlugins::Facet::FacetItem.find_by(id: id)
    when 'fe_navigation_item'
      entry = DataModules::FeNavigation::FeNavigationItem.find_by(id: id)
    end
    entry
  end

  def read_cache_file(cache_file_path)
    file = File.read(cache_file_path)
    JSON.parse(file)
  end

  def write_cache_file(cache_file_path, content)
    File.open(cache_file_path, 'w') do |f|
      f.write(content)
    end
  end

  def get_entries(model_class, area)
    entries = model_class.for_json.
      includes(model_class.default_includes).
      where(area: area)
    entries
  end

  def get_entries_with_translations(model_class, area)
    entries = model_class.for_json.
      includes(:translation_caches).
      where(area: area)
    entries
  end

end
