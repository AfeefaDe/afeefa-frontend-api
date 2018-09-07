require 'test_helper'

class CacheBuilderTest < ActiveSupport::TestCase

  setup do
    cache_builder.purge
  end

  test 'cache path in test directory' do
    assert CacheBuilder::CACHE_PATH.include?('/test/cache')
  end


  test 'purge removes all files' do
    FileUtils.touch(File.join(CacheBuilder::CACHE_PATH, 'file.txt').to_s)
    FileUtils.touch(File.join(CacheBuilder::CACHE_PATH, 'file2.txt').to_s)

    assert File.file?(File.join(CacheBuilder::CACHE_PATH, 'file.txt').to_s)
    assert File.file?(File.join(CacheBuilder::CACHE_PATH, 'file2.txt').to_s)
    assert File.file?(File.join(CacheBuilder::CACHE_PATH, '.keep').to_s)

    cache_builder.purge

    assert_not File.file?(File.join(CacheBuilder::CACHE_PATH, 'file.txt').to_s)
    assert_not File.file?(File.join(CacheBuilder::CACHE_PATH, 'file2.txt').to_s)
    assert File.file?(File.join(CacheBuilder::CACHE_PATH, '.keep').to_s)
  end

  test 'build entries creates empty entries files if no entry exists' do
    cache_builder.send(:build_entries)

    assert File.file?(File.join(CacheBuilder::CACHE_PATH, "entries-bautzen.json").to_s)
    file = File.read(File.join(CacheBuilder::CACHE_PATH, "entries-bautzen.json").to_s)
    assert_equal '{"orgas":[],"offers":[],"events":[]}', file
  end

  test 'build entries' do
    orga = create(:orga, title: 'orga.1.title', area: 'bautzen')
    orga2 = create(:orga, title: 'orga.2.title', area: 'bautzen')
    event = create(:event, title: 'event.1.title', area: 'bautzen')
    offer = create(:offer, title: 'offer.1.title', area: 'bautzen')

    cache_builder.send(:build_entries)

    assert File.file?(File.join(CacheBuilder::CACHE_PATH, "entries-bautzen.json").to_s)
    file = File.read(File.join(CacheBuilder::CACHE_PATH, "entries-bautzen.json").to_s)
    json = JSON.parse(file)

    assert_equal 3, json['orgas'].length
    assert_equal 1, json['events'].length
    assert_equal 1, json['offers'].length
    assert_equal orga.id, json['orgas'][0]['id']
    assert_equal orga2.id, json['orgas'][1]['id']
    assert_equal event.hosts.first.id, json['orgas'][2]['id']
    assert_equal event.id, json['events'][0]['id']
    assert_equal offer.id, json['offers'][0]['id']
  end

  test 'translate_all creates empty entries files if no entry exists' do
    cache_builder.send(:translate_all)

    locales = [Translation::DEFAULT_LOCALE] + Translation::TRANSLATABLE_LOCALES
    locales.each do |locale|
      assert File.file?(File.join(CacheBuilder::CACHE_PATH, "lang-#{locale}-bautzen.json").to_s)
      file = File.read(File.join(CacheBuilder::CACHE_PATH, "lang-#{locale}-bautzen.json").to_s)
      assert_equal '{"orgas":[],"offers":[],"events":[],"facet_items":[],"navigation_items":[]}', file
    end
  end

  test 'build facets creates empty facet file if no facet item exists' do
    cache_builder.send(:build_facets)

    assert File.file?(File.join(CacheBuilder::CACHE_PATH, "facets.json").to_s)
    file = File.read(File.join(CacheBuilder::CACHE_PATH, "facets.json").to_s)
    assert_equal '[]', file
  end

  test 'build facets' do
    create(:facet_with_items_and_sub_items)

    cache_builder.send(:build_facets)

    assert File.file?(File.join(CacheBuilder::CACHE_PATH, "facets.json").to_s)
    file = File.read(File.join(CacheBuilder::CACHE_PATH, "facets.json").to_s)
    json = JSON.parse(file)

    assert_equal 1, json.length
    assert_equal 2, json[0]['facet_items'].length
    assert_equal 2, json[0]['facet_items'][0]['sub_items'].length
    assert_equal 2, json[0]['facet_items'][1]['sub_items'].length
  end

  test 'build navigations creates empty navigation files if no navigation exists' do
    cache_builder.send(:build_navigations)

    assert File.file?(File.join(CacheBuilder::CACHE_PATH, "navigation-bautzen.json").to_s)
    file = File.read(File.join(CacheBuilder::CACHE_PATH, "navigation-bautzen.json").to_s)
    assert_equal '[]', file
  end

  test 'build navigations' do
    create(:fe_navigation_with_items_and_sub_items, area: 'leipzig')

    cache_builder.send(:build_navigations)

    assert File.file?(File.join(CacheBuilder::CACHE_PATH, "navigation-leipzig.json").to_s)
    file = File.read(File.join(CacheBuilder::CACHE_PATH, "navigation-leipzig.json").to_s)
    json = JSON.parse(file)

    assert_equal 2, json.length
    assert_equal 2, json[0]['sub_items'].length
    assert_equal 2, json[1]['sub_items'].length
  end

  test 'translate all uses DEFAULT_LOCALE if no translation present' do
    orga = create(:orga, title: 'orga.1.title', area: 'bautzen')
    orga2 = create(:orga, title: 'orga.2.title', area: 'bautzen')
    event = create(:event, title: 'event.1.title', area: 'bautzen')
    offer = create(:offer, title: 'offer.1.title', area: 'bautzen')

    cache_builder.send(:translate_all)

    locales = [Translation::DEFAULT_LOCALE] + Translation::TRANSLATABLE_LOCALES
    locales.each do |locale|
      assert File.file?(File.join(CacheBuilder::CACHE_PATH, "lang-#{locale}-bautzen.json").to_s)
      file = File.read(File.join(CacheBuilder::CACHE_PATH, "lang-#{locale}-bautzen.json").to_s)
      json = JSON.parse(file)

      assert_equal 3, json['orgas'].length
      assert_equal 1, json['events'].length
      assert_equal 1, json['offers'].length
      assert_equal 'orga.1.title', json['orgas'][0]['title']
      assert_equal 'orga.2.title', json['orgas'][1]['title']
      assert_equal 'orga for event.1.title', json['orgas'][2]['title']
      assert_equal 'event.1.title', json['events'][0]['title']
      assert_equal 'offer.1.title', json['offers'][0]['title']
    end
  end

  test 'translate all uses values of translation cache if present' do
    orga = create(:orga, title: 'orga.1.title', short_description: 'orga.1.short_description', area: 'bautzen', translated_locales: ['fr', 'pa', 'ur'])
    orga2 = create(:orga, title: 'orga.2.title', area: 'bautzen', translated_locales: ['en', 'pa', 'ur'])
    event = create(:event, title: 'event.1.title', area: 'bautzen', translated_locales: ['fr', 'pa', 'ru'])

    facet = create(:facet_with_items_and_sub_items)
    facet_item = facet.facet_items.first
    facet_item.update(title: 'facet_item.1.title')
    facet_item.translation_caches << build(:translation, cacheable: facet_item, language: 'en', title: facet_item.title + '_en')

    navigation = create(:fe_navigation_with_items_and_sub_items, area: 'bautzen')
    navigation_item = navigation.navigation_items.first
    navigation_item.update(title: 'navigation_item.4.title')
    navigation_item.translation_caches << build(:translation, cacheable: navigation_item, language: 'en', title: navigation_item.title + '_en')

    cache_builder.send(:translate_all)

    locales = [Translation::DEFAULT_LOCALE] + Translation::TRANSLATABLE_LOCALES
    locales.each do |locale|
      assert File.file?(File.join(CacheBuilder::CACHE_PATH, "lang-#{locale}-bautzen.json").to_s)
      file = File.read(File.join(CacheBuilder::CACHE_PATH, "lang-#{locale}-bautzen.json").to_s)
      json = JSON.parse(file)

      assert_equal 3, json['orgas'].length
      assert_equal 1, json['events'].length
      assert_equal 6, json['facet_items'].length
      assert_equal 6, json['navigation_items'].length

      if ['fr', 'pa', 'ur'].include?(locale)
        assert_equal "orga.1.title_#{locale}", json['orgas'][0]['title']
        assert_equal "orga.1.short_description_#{locale}", json['orgas'][0]['short_description']
      else
        assert_equal 'orga.1.title', json['orgas'][0]['title']
        assert_equal 'orga.1.short_description', json['orgas'][0]['short_description']
      end

      if ['en', 'pa', 'ur'].include?(locale)
        assert_equal "orga.2.title_#{locale}", json['orgas'][1]['title']
      else
        assert_equal 'orga.2.title', json['orgas'][1]['title']
      end

      if locale == 'en'
        assert_equal "facet_item.1.title_en", json['facet_items'][0]['title']
        assert_equal "navigation_item.4.title_en", json['navigation_items'][0]['title']
      else
        assert_equal "facet_item.1.title", json['facet_items'][0]['title']
        assert_equal "navigation_item.4.title", json['navigation_items'][0]['title']
      end

      assert_equal "orga for event.1.title", json['orgas'][2]['title']

      if ['fr', 'pa', 'ru'].include?(locale)
        assert_equal "event.1.title_#{locale}", json['events'][0]['title']
      else
        assert_equal 'event.1.title', json['events'][0]['title']
      end
    end
  end

  test 'translate all separates areas' do
    orga = create(:orga, title: 'orga.1.title', area: 'bautzen')
    orga2 = create(:orga, title: 'orga.2.title', area: 'leipzig')
    event = create(:event, title: 'event.1.title', area: 'dresden')

    navigation = create(:fe_navigation_with_items_and_sub_items, area: 'bautzen')
    navigation2 = create(:fe_navigation_with_items, area: 'leipzig')

    cache_builder.send(:translate_all)

    locales = [Translation::DEFAULT_LOCALE] + Translation::TRANSLATABLE_LOCALES
    locales.each do |locale|
      assert File.file?(File.join(CacheBuilder::CACHE_PATH, "lang-#{locale}-bautzen.json").to_s)
      file = File.read(File.join(CacheBuilder::CACHE_PATH, "lang-#{locale}-bautzen.json").to_s)
      json = JSON.parse(file)
      assert_equal 1, json['orgas'].length
      assert_equal 0, json['events'].length
      assert_equal 6, json['navigation_items'].length
      assert_equal 'orga.1.title', json['orgas'][0]['title']
      assert_equal navigation.navigation_items.first.title, json['navigation_items'][0]['title']

      assert File.file?(File.join(CacheBuilder::CACHE_PATH, "lang-#{locale}-leipzig.json").to_s)
      file = File.read(File.join(CacheBuilder::CACHE_PATH, "lang-#{locale}-leipzig.json").to_s)
      json = JSON.parse(file)
      assert_equal 1, json['orgas'].length
      assert_equal 0, json['events'].length
      assert_equal 2, json['navigation_items'].length
      assert_equal 'orga.2.title', json['orgas'][0]['title']
      assert_equal navigation2.navigation_items.first.title, json['navigation_items'][0]['title']

      assert File.file?(File.join(CacheBuilder::CACHE_PATH, "lang-#{locale}-dresden.json").to_s)
      file = File.read(File.join(CacheBuilder::CACHE_PATH, "lang-#{locale}-dresden.json").to_s)
      json = JSON.parse(file)
      assert_equal 1, json['orgas'].length
      assert_equal 1, json['events'].length
      assert_equal 0, json['navigation_items'].length
      assert_equal "orga for event.1.title", json['orgas'][0]['title']
      assert_equal 'event.1.title', json['events'][0]['title']
    end
  end

  test 'build all' do
    cache_builder.expects(:build_facets)
    cache_builder.expects(:build_navigations)
    cache_builder.expects(:build_entries)
    cache_builder.expects(:translate_all)

    cache_builder.build_all
  end

  test 'translate entry' do
    orga = create(:orga, title: 'orga.1.title', area: 'leipzig')
    orga2 = create(:orga, title: 'orga.2.title', area: 'leipzig')
    cache_builder.send(:build_all)

    assert File.file?(File.join(CacheBuilder::CACHE_PATH, "lang-fr-leipzig.json").to_s)
    file = File.read(File.join(CacheBuilder::CACHE_PATH, "lang-fr-leipzig.json").to_s)
    json = JSON.parse(file)
    assert_equal 2, json['orgas'].length
    assert_equal 'orga.1.title', json['orgas'][0]['title']
    assert_equal 'orga.2.title', json['orgas'][1]['title']

    translation = create(:translation, cacheable: orga, language: 'fr', title: 'orga.1.title_fr')

    cache_builder.translate_entry('orga', orga.id.to_s, 'fr')

    assert File.file?(File.join(CacheBuilder::CACHE_PATH, "lang-fr-leipzig.json").to_s)
    file = File.read(File.join(CacheBuilder::CACHE_PATH, "lang-fr-leipzig.json").to_s)
    json = JSON.parse(file)

    assert_equal 2, json['orgas'].length
    assert_equal 'orga.1.title_fr', json['orgas'][0]['title']
    assert_equal 'orga.2.title', json['orgas'][1]['title']
  end

  test 'translate facet item' do
    facet = create(:facet_with_items_and_sub_items)
    facet_item = facet.facet_items.first
    facet_item.update(title: 'facet_item.1.title')
    facet_item2 = facet.facet_items.last
    facet_item2.update(title: 'facet_item.4.title')

    cache_builder.send(:build_all)

    assert File.file?(File.join(CacheBuilder::CACHE_PATH, "lang-fr-leipzig.json").to_s)
    file = File.read(File.join(CacheBuilder::CACHE_PATH, "lang-fr-leipzig.json").to_s)
    json = JSON.parse(file)
    assert_equal 6, json['facet_items'].length
    assert_equal 'facet_item.1.title', json['facet_items'][0]['title']
    assert_equal 'facet_item.4.title', json['facet_items'][5]['title']

    translation = create(:translation, cacheable: facet_item, language: 'fr', title: 'facet_item.1.title_fr')

    cache_builder.translate_entry('facet_item', facet_item.id.to_s, 'fr')

    assert File.file?(File.join(CacheBuilder::CACHE_PATH, "lang-fr-leipzig.json").to_s)
    file = File.read(File.join(CacheBuilder::CACHE_PATH, "lang-fr-leipzig.json").to_s)
    json = JSON.parse(file)

    assert_equal 6, json['facet_items'].length
    assert_equal 'facet_item.1.title_fr', json['facet_items'][0]['title']
    assert_equal 'facet_item.4.title', json['facet_items'][5]['title']
  end

  test 'translate navigation item' do
    navigation = create(:fe_navigation_with_items_and_sub_items, area: 'leipzig')
    navigation_item = navigation.navigation_items.first
    navigation_item.update(title: 'navigation_item.1.title')

    cache_builder.send(:build_all)

    assert File.file?(File.join(CacheBuilder::CACHE_PATH, "lang-fr-leipzig.json").to_s)
    file = File.read(File.join(CacheBuilder::CACHE_PATH, "lang-fr-leipzig.json").to_s)
    json = JSON.parse(file)
    assert_equal 6, json['navigation_items'].length
    assert_equal 'navigation_item.1.title', json['navigation_items'][0]['title']

    translation = create(:translation, cacheable: navigation_item, language: 'fr', title: 'navigation_item.1.title_fr')

    cache_builder.translate_entry('navigation_item', navigation_item.id.to_s, 'fr')

    assert File.file?(File.join(CacheBuilder::CACHE_PATH, "lang-fr-leipzig.json").to_s)
    file = File.read(File.join(CacheBuilder::CACHE_PATH, "lang-fr-leipzig.json").to_s)
    json = JSON.parse(file)

    assert_equal 6, json['navigation_items'].length
    assert_equal 'navigation_item.1.title_fr', json['navigation_items'][0]['title']
  end

  test 'translate entry with int id' do
    orga = create(:orga, title: 'orga.1.title', area: 'leipzig')
    cache_builder.send(:build_all)

    translation = create(:translation, cacheable: orga, language: 'fr', title: 'orga.1.title_fr')

    cache_builder.translate_entry('orga', orga.id, 'fr')

    file = File.read(File.join(CacheBuilder::CACHE_PATH, "lang-fr-leipzig.json").to_s)
    json = JSON.parse(file)

    assert_equal 'orga.1.title_fr', json['orgas'][0]['title']
  end

  test 'update entry title' do
    orga = create(:orga, title: 'orga.1.title', area: 'leipzig')
    orga2 = create(:orga, title: 'orga.2.title', area: 'leipzig')
    cache_builder.send(:build_all)

    locales = [Translation::DEFAULT_LOCALE] + Translation::TRANSLATABLE_LOCALES
    locales.each do |locale|
      assert File.file?(File.join(CacheBuilder::CACHE_PATH, "lang-#{locale}-leipzig.json").to_s)
      file = File.read(File.join(CacheBuilder::CACHE_PATH, "lang-#{locale}-leipzig.json").to_s)
      json = JSON.parse(file)
      assert_equal 2, json['orgas'].length
      assert_equal 'orga.1.title', json['orgas'][0]['title']
      assert_equal 'orga.2.title', json['orgas'][1]['title']
    end

    orga.update(title: 'orga.1.title.new')
    translation = create(:translation, cacheable: orga, language: 'fr', title: 'orga.1.title.new_fr')
    translation = create(:translation, cacheable: orga, language: 'ur', title: 'orga.1.title.new_ur')

    cache_builder.update_entry('orga', orga.id)

    locales = [Translation::DEFAULT_LOCALE] + Translation::TRANSLATABLE_LOCALES
    locales.each do |locale|
      assert File.file?(File.join(CacheBuilder::CACHE_PATH, "lang-#{locale}-leipzig.json").to_s)
      file = File.read(File.join(CacheBuilder::CACHE_PATH, "lang-#{locale}-leipzig.json").to_s)
      json = JSON.parse(file)
      assert_equal 2, json['orgas'].length
      if ['fr', 'ur'].include?(locale)
        assert_equal "orga.1.title.new_#{locale}", json['orgas'][0]['title']
      else
        assert_equal 'orga.1.title.new', json['orgas'][0]['title']
      end
      assert_equal 'orga.2.title', json['orgas'][1]['title']
    end

  end

  test 'update entry attribute' do
    orga = create(:orga, title: 'orga.1.title', area: 'leipzig')
    cache_builder.send(:build_all)

    assert File.file?(File.join(CacheBuilder::CACHE_PATH, "entries-leipzig.json").to_s)
    file = File.read(File.join(CacheBuilder::CACHE_PATH, "entries-leipzig.json").to_s)
    json = JSON.parse(file)
    assert_equal 1, json['orgas'].length
    assert !json['orgas'][0]['certified']

    orga.update(certified_sfr: true)

    cache_builder.update_entry('orga', orga.id)

    assert File.file?(File.join(CacheBuilder::CACHE_PATH, "entries-leipzig.json").to_s)
    file = File.read(File.join(CacheBuilder::CACHE_PATH, "entries-leipzig.json").to_s)
    json = JSON.parse(file)
    assert_equal 1, json['orgas'].length
    assert json['orgas'][0]['certified']
  end

  test 'update entry with new entry' do
    orga = create(:orga, title: 'orga.1.title', area: 'leipzig')
    cache_builder.send(:build_all)

    locales = [Translation::DEFAULT_LOCALE] + Translation::TRANSLATABLE_LOCALES
    locales.each do |locale|
      assert File.file?(File.join(CacheBuilder::CACHE_PATH, "lang-#{locale}-leipzig.json").to_s)
      file = File.read(File.join(CacheBuilder::CACHE_PATH, "lang-#{locale}-leipzig.json").to_s)
      json = JSON.parse(file)
      assert_equal 1, json['orgas'].length
      assert_equal 0, json['facet_items'].length
      assert_equal 0, json['navigation_items'].length
      assert_equal 'orga.1.title', json['orgas'][0]['title']
    end

    orga2 = create(:orga, title: 'orga.2.title', area: 'leipzig')

    facet = create(:facet_with_items_and_sub_items)
    facet_item = facet.facet_items.first
    facet_item.update(title: 'facet_item.1.title')

    navigation = create(:fe_navigation_with_items, area: 'leipzig')
    navigation_item = navigation.navigation_items.first
    navigation_item.update(title: 'navigation_item.1.title')

    cache_builder.update_entry('orga', orga2.id)
    cache_builder.update_entry('facet_item', facet_item.id)
    cache_builder.update_entry('navigation_item', navigation_item.id)

    locales = [Translation::DEFAULT_LOCALE] + Translation::TRANSLATABLE_LOCALES
    locales.each do |locale|
      assert File.file?(File.join(CacheBuilder::CACHE_PATH, "lang-#{locale}-leipzig.json").to_s)
      file = File.read(File.join(CacheBuilder::CACHE_PATH, "lang-#{locale}-leipzig.json").to_s)
      json = JSON.parse(file)
      assert_equal 2, json['orgas'].length
      assert_equal 1, json['facet_items'].length
      assert_equal 1, json['navigation_items'].length
      assert_equal 'orga.1.title', json['orgas'][0]['title']
      assert_equal 'orga.2.title', json['orgas'][1]['title']
      assert_equal 'facet_item.1.title', json['facet_items'][0]['title']
      assert_equal 'navigation_item.1.title', json['navigation_items'][0]['title']
    end

  end

  test 'update entry with deactivated entry' do
    orga = create(:orga, title: 'orga.1.title', area: 'leipzig')
    orga2 = create(:orga, title: 'orga.2.title', area: 'leipzig')
    cache_builder.send(:build_all)

    locales = [Translation::DEFAULT_LOCALE] + Translation::TRANSLATABLE_LOCALES
    locales.each do |locale|
      assert File.file?(File.join(CacheBuilder::CACHE_PATH, "lang-#{locale}-leipzig.json").to_s)
      file = File.read(File.join(CacheBuilder::CACHE_PATH, "lang-#{locale}-leipzig.json").to_s)
      json = JSON.parse(file)
      assert_equal 2, json['orgas'].length
      assert_equal 'orga.1.title', json['orgas'][0]['title']
      assert_equal 'orga.2.title', json['orgas'][1]['title']
    end

    orga.update(state: 'deactivated')
    cache_builder.update_entry('orga', orga.id)

    locales = [Translation::DEFAULT_LOCALE] + Translation::TRANSLATABLE_LOCALES
    locales.each do |locale|
      assert File.file?(File.join(CacheBuilder::CACHE_PATH, "lang-#{locale}-leipzig.json").to_s)
      file = File.read(File.join(CacheBuilder::CACHE_PATH, "lang-#{locale}-leipzig.json").to_s)
      json = JSON.parse(file)
      assert_equal 1, json['orgas'].length
      assert_equal 'orga.2.title', json['orgas'][0]['title']
    end

    orga.update(state: 'active')
    cache_builder.update_entry('orga', orga.id)

    locales = [Translation::DEFAULT_LOCALE] + Translation::TRANSLATABLE_LOCALES
    locales.each do |locale|
      assert File.file?(File.join(CacheBuilder::CACHE_PATH, "lang-#{locale}-leipzig.json").to_s)
      file = File.read(File.join(CacheBuilder::CACHE_PATH, "lang-#{locale}-leipzig.json").to_s)
      json = JSON.parse(file)
      assert_equal 2, json['orgas'].length
      assert_equal 'orga.2.title', json['orgas'][0]['title']
      assert_equal 'orga.1.title', json['orgas'][1]['title']
    end

  end

  test 'remove entry' do
    orga = create(:orga, title: 'orga.1.title', area: 'leipzig')
    orga2 = create(:orga, title: 'orga.2.title', area: 'leipzig')
    orga3 = create(:orga, title: 'orga.3.title', area: 'leipzig')

    facet = create(:facet_with_items_and_sub_items)
    facet_item = facet.facet_items.first

    navigation = create(:fe_navigation_with_items_and_sub_items, area: 'leipzig')
    navigation_item = navigation.navigation_items.first

    cache_builder.send(:build_all)

    orga2.destroy!
    facet_item.destroy!
    navigation_item.destroy!

    cache_builder.remove_entry('leipzig', 'orga', orga2.id.to_s)
    cache_builder.remove_entry('leipzig', 'facet_item', facet_item.id.to_s)
    cache_builder.remove_entry('leipzig', 'navigation_item', navigation_item.id.to_s)

    locales = [Translation::DEFAULT_LOCALE] + Translation::TRANSLATABLE_LOCALES
    locales.each do |locale|
      assert File.file?(File.join(CacheBuilder::CACHE_PATH, "lang-#{locale}-leipzig.json").to_s)
      file = File.read(File.join(CacheBuilder::CACHE_PATH, "lang-#{locale}-leipzig.json").to_s)
      json = JSON.parse(file)
      assert_equal 2, json['orgas'].length
      assert_equal 5, json['facet_items'].length
      assert_equal 5, json['navigation_items'].length
      assert_equal 'orga.1.title', json['orgas'][0]['title']
      assert_equal 'orga.3.title', json['orgas'][1]['title']
    end

    assert File.file?(File.join(CacheBuilder::CACHE_PATH, "entries-leipzig.json").to_s)
    file = File.read(File.join(CacheBuilder::CACHE_PATH, "entries-leipzig.json").to_s)
    json = JSON.parse(file)
    assert_equal 2, json['orgas'].length
    assert_equal orga.id, json['orgas'][0]['id']
    assert_equal orga3.id, json['orgas'][1]['id']

    assert File.file?(File.join(CacheBuilder::CACHE_PATH, "facets.json").to_s)
    file = File.read(File.join(CacheBuilder::CACHE_PATH, "facets.json").to_s)
    json = JSON.parse(file)

    assert_equal 1, json.length
    assert_equal 1, json[0]['facet_items'].length
    assert_equal 2, json[0]['facet_items'][0]['sub_items'].length

    assert File.file?(File.join(CacheBuilder::CACHE_PATH, "navigation-leipzig.json").to_s)
    file = File.read(File.join(CacheBuilder::CACHE_PATH, "navigation-leipzig.json").to_s)
    json = JSON.parse(file)

    assert_equal 1, json.length
    assert_equal 2, json[0]['sub_items'].length
  end

  test 'remove entry with int id' do
    orga = create(:orga, title: 'orga.1.title', area: 'leipzig')
    cache_builder.send(:build_all)

    orga.destroy!

    cache_builder.remove_entry('leipzig', 'orga', orga.id)

    locales = [Translation::DEFAULT_LOCALE] + Translation::TRANSLATABLE_LOCALES
    locales.each do |locale|
      file = File.read(File.join(CacheBuilder::CACHE_PATH, "lang-#{locale}-leipzig.json").to_s)
      json = JSON.parse(file)
      assert_equal 0, json['orgas'].length
    end

  end

  private

  def cache_builder
    @cache_builder ||= CacheBuilder.new
  end

end
