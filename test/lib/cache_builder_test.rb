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

  test 'build locale creates empty locale files if no entry exists' do
    locales = [Translation::DEFAULT_LOCALE] + Translation::TRANSLATABLE_LOCALES
    locales.each do |locale|
      cache_builder.send(:build_locale, 'bautzen', locale)

      assert File.file?(File.join(CacheBuilder::CACHE_PATH, "bautzen-#{locale}.json").to_s)
      file = File.read(File.join(CacheBuilder::CACHE_PATH, "bautzen-#{locale}.json").to_s)
      assert_equal '{"marketentries":[]}', file
    end
  end

  test 'build locale uses DEFAULT_LOCALE if no translation present' do
    orga = create(:orga, title: 'orga.1.title', area: 'bautzen')
    orga2 = create(:orga, title: 'orga.2.title', area: 'bautzen')
    event = create(:event, title: 'event.1.title', area: 'bautzen')

    locales = [Translation::DEFAULT_LOCALE] + Translation::TRANSLATABLE_LOCALES
    locales.each do |locale|
      cache_builder.send(:build_locale, 'bautzen', locale)

      assert File.file?(File.join(CacheBuilder::CACHE_PATH, "bautzen-#{locale}.json").to_s)
      file = File.read(File.join(CacheBuilder::CACHE_PATH, "bautzen-#{locale}.json").to_s)
      json = JSON.parse(file)

      assert_equal 4, json['marketentries'].length
      assert_equal 'orga.1.title', json['marketentries'][0]['name']
      assert_equal 'orga.2.title', json['marketentries'][1]['name']
      assert_equal 'orga for event.1.title', json['marketentries'][2]['name']
      assert_equal 'event.1.title', json['marketentries'][3]['name']
    end
  end

  test 'build locale uses values of translation cache if present' do
    orga = create(:orga, title: 'orga.1.title', short_description: 'orga.1.short_description', area: 'bautzen', translated_locales: ['fr', 'pa', 'ur'])
    orga2 = create(:orga, title: 'orga.2.title', area: 'bautzen', translated_locales: ['en', 'pa', 'ur'])
    event = create(:event, title: 'event.1.title', area: 'bautzen', translated_locales: ['fr', 'pa', 'ru'])

    locales = [Translation::DEFAULT_LOCALE] + Translation::TRANSLATABLE_LOCALES
    locales.each do |locale|
      cache_builder.send(:build_locale, 'bautzen', locale)

      assert File.file?(File.join(CacheBuilder::CACHE_PATH, "bautzen-#{locale}.json").to_s)
      file = File.read(File.join(CacheBuilder::CACHE_PATH, "bautzen-#{locale}.json").to_s)
      json = JSON.parse(file)

      assert_equal 4, json['marketentries'].length

      if ['fr', 'pa', 'ur'].include?(locale)
        assert_equal "orga.1.title_#{locale}", json['marketentries'][0]['name']
        assert_equal "orga.1.short_description_#{locale}", json['marketentries'][0]['descriptionShort']
      else
        assert_equal 'orga.1.title', json['marketentries'][0]['name']
        assert_equal 'orga.1.short_description', json['marketentries'][0]['descriptionShort']
      end

      if ['en', 'pa', 'ur'].include?(locale)
        assert_equal "orga.2.title_#{locale}", json['marketentries'][1]['name']
      else
        assert_equal 'orga.2.title', json['marketentries'][1]['name']
      end

      assert_equal "orga for event.1.title", json['marketentries'][2]['name']

      if ['fr', 'pa', 'ru'].include?(locale)
        assert_equal "event.1.title_#{locale}", json['marketentries'][3]['name']
      else
        assert_equal 'event.1.title', json['marketentries'][3]['name']
      end
    end
  end

  test 'build locale separates areas' do
    orga = create(:orga, title: 'orga.1.title', area: 'bautzen')
    orga2 = create(:orga, title: 'orga.2.title', area: 'leipzig')
    event = create(:event, title: 'event.1.title', area: 'dresden')

    locales = [Translation::DEFAULT_LOCALE] + Translation::TRANSLATABLE_LOCALES
    locales.each do |locale|
      cache_builder.send(:build_locale, 'bautzen', locale)
      cache_builder.send(:build_locale, 'leipzig', locale)
      cache_builder.send(:build_locale, 'dresden', locale)

      assert File.file?(File.join(CacheBuilder::CACHE_PATH, "bautzen-#{locale}.json").to_s)
      file = File.read(File.join(CacheBuilder::CACHE_PATH, "bautzen-#{locale}.json").to_s)
      json = JSON.parse(file)
      assert_equal 1, json['marketentries'].length
      assert_equal 'orga.1.title', json['marketentries'][0]['name']

      assert File.file?(File.join(CacheBuilder::CACHE_PATH, "leipzig-#{locale}.json").to_s)
      file = File.read(File.join(CacheBuilder::CACHE_PATH, "leipzig-#{locale}.json").to_s)
      json = JSON.parse(file)
      assert_equal 1, json['marketentries'].length
      assert_equal 'orga.2.title', json['marketentries'][0]['name']

      assert File.file?(File.join(CacheBuilder::CACHE_PATH, "dresden-#{locale}.json").to_s)
      file = File.read(File.join(CacheBuilder::CACHE_PATH, "dresden-#{locale}.json").to_s)
      json = JSON.parse(file)
      assert_equal 2, json['marketentries'].length
      assert_equal "orga for event.1.title", json['marketentries'][0]['name']
      assert_equal 'event.1.title', json['marketentries'][1]['name']
    end
  end

  test 'build all' do
    locales = [Translation::DEFAULT_LOCALE] + Translation::TRANSLATABLE_LOCALES
    areas = Translation::AREAS

    count = 0
    areas.each do |area|
      locales.each do |locale|
        cache_builder.expects(:build_locale).with(area, locale)
        count += 1
      end
    end

    assert_equal 45, count

    cache_builder.build_all
  end

  test 'translate entry' do
    orga = create(:orga, title: 'orga.1.title', area: 'leipzig')
    orga2 = create(:orga, title: 'orga.2.title', area: 'leipzig')
    cache_builder.send(:build_locale, 'leipzig', 'fr')

    assert File.file?(File.join(CacheBuilder::CACHE_PATH, "leipzig-fr.json").to_s)
    file = File.read(File.join(CacheBuilder::CACHE_PATH, "leipzig-fr.json").to_s)
    json = JSON.parse(file)
    assert_equal 2, json['marketentries'].length
    assert_equal 'orga.1.title', json['marketentries'][0]['name']
    assert_equal 'orga.2.title', json['marketentries'][1]['name']

    translation = create(:translation, cacheable: orga, language: 'fr', title: 'orga.1.title_fr')

    cache_builder.translate_entry('orga', orga.id.to_s, 'fr')

    assert File.file?(File.join(CacheBuilder::CACHE_PATH, "leipzig-fr.json").to_s)
    file = File.read(File.join(CacheBuilder::CACHE_PATH, "leipzig-fr.json").to_s)
    json = JSON.parse(file)

    assert_equal 2, json['marketentries'].length
    assert_equal 'orga.1.title_fr', json['marketentries'][0]['name']
    assert_equal 'orga.2.title', json['marketentries'][1]['name']
  end

  test 'translate entry with int id' do
    orga = create(:orga, title: 'orga.1.title', area: 'leipzig')
    cache_builder.send(:build_locale, 'leipzig', 'fr')

    translation = create(:translation, cacheable: orga, language: 'fr', title: 'orga.1.title_fr')

    cache_builder.translate_entry('orga', orga.id, 'fr')

    file = File.read(File.join(CacheBuilder::CACHE_PATH, "leipzig-fr.json").to_s)
    json = JSON.parse(file)

    assert_equal 'orga.1.title_fr', json['marketentries'][0]['name']
  end

  test 'update entry' do
    orga = create(:orga, title: 'orga.1.title', area: 'leipzig')
    orga2 = create(:orga, title: 'orga.2.title', area: 'leipzig')
    cache_builder.send(:build_area, 'leipzig')

    locales = [Translation::DEFAULT_LOCALE] + Translation::TRANSLATABLE_LOCALES
    locales.each do |locale|
      assert File.file?(File.join(CacheBuilder::CACHE_PATH, "leipzig-#{locale}.json").to_s)
      file = File.read(File.join(CacheBuilder::CACHE_PATH, "leipzig-#{locale}.json").to_s)
      json = JSON.parse(file)
      assert_equal 2, json['marketentries'].length
      assert_equal 'orga.1.title', json['marketentries'][0]['name']
      assert_equal 'orga.2.title', json['marketentries'][1]['name']
    end

    orga.update(title: 'orga.1.title.new')
    translation = create(:translation, cacheable: orga, language: 'fr', title: 'orga.1.title.new_fr')
    translation = create(:translation, cacheable: orga, language: 'ur', title: 'orga.1.title.new_ur')

    cache_builder.update_entry('orga', orga.id)

    locales = [Translation::DEFAULT_LOCALE] + Translation::TRANSLATABLE_LOCALES
    locales.each do |locale|
      assert File.file?(File.join(CacheBuilder::CACHE_PATH, "leipzig-#{locale}.json").to_s)
      file = File.read(File.join(CacheBuilder::CACHE_PATH, "leipzig-#{locale}.json").to_s)
      json = JSON.parse(file)
      assert_equal 2, json['marketentries'].length
      if ['fr', 'ur'].include?(locale)
        assert_equal "orga.1.title.new_#{locale}", json['marketentries'][0]['name']
      else
        assert_equal 'orga.1.title.new', json['marketentries'][0]['name']
      end
      assert_equal 'orga.2.title', json['marketentries'][1]['name']
    end

  end

  test 'remove entry' do
    orga = create(:orga, title: 'orga.1.title', area: 'leipzig')
    orga2 = create(:orga, title: 'orga.2.title', area: 'leipzig')
    orga3 = create(:orga, title: 'orga.3.title', area: 'leipzig')
    cache_builder.send(:build_area, 'leipzig')

    orga2.destroy!

    cache_builder.remove_entry('leipzig', 'orga', orga2.id.to_s)

    locales = [Translation::DEFAULT_LOCALE] + Translation::TRANSLATABLE_LOCALES
    locales.each do |locale|
      assert File.file?(File.join(CacheBuilder::CACHE_PATH, "leipzig-#{locale}.json").to_s)
      file = File.read(File.join(CacheBuilder::CACHE_PATH, "leipzig-#{locale}.json").to_s)
      json = JSON.parse(file)
      assert_equal 2, json['marketentries'].length
      assert_equal 'orga.1.title', json['marketentries'][0]['name']
      assert_equal 'orga.3.title', json['marketentries'][1]['name']
    end

  end

  test 'remove entry with int id' do
    orga = create(:orga, title: 'orga.1.title', area: 'leipzig')
    cache_builder.send(:build_area, 'leipzig')

    orga.destroy!

    cache_builder.remove_entry('leipzig', 'orga', orga.id)

    locales = [Translation::DEFAULT_LOCALE] + Translation::TRANSLATABLE_LOCALES
    locales.each do |locale|
      file = File.read(File.join(CacheBuilder::CACHE_PATH, "leipzig-#{locale}.json").to_s)
      json = JSON.parse(file)
      assert_equal 0, json['marketentries'].length
    end

  end

  private

  def cache_builder
    @cache_builder ||= CacheBuilder.new
  end

end
