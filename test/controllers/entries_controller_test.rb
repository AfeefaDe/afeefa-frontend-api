require 'test_helper'

class EntriesControllerTest < ActionController::TestCase

  setup do
    orga = Orga.new(state: :active)
    assert orga.save(validate: false)
    @event = Event.new(state: :active, date_start: 5.days.from_now)
    assert @event.save(validate: false)
    location = @event.locations.new
    assert location.save(validate: false)
    event2 = Event.new(state: :active, date_start: 5.days.from_now)
    assert event2.save(validate: false)

    FileUtils.rm_rf(TranslationCacheMetaDatum::CACHE_PATH)
    TranslationCacheMetaDatum.delete_all

    init_translation_cache('de')
  end

  test 'get index' do
    get :index, params: { locale: 'de' }
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 4, json['marketentries'].size
    assert @event = json['marketentries'].last
    assert @event.key?('dateFrom')
    assert @event.key?('timeFrom')
    assert @event.key?('dateTo')
    assert @event.key?('timeTo')
  end

  test 'get de by default' do
    get :index, params: { locale: 'de' }
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 4, json['marketentries'].size
    assert @event = json['marketentries'].last
    assert @event.key?('dateFrom')
    assert @event.key?('timeFrom')
    assert @event.key?('dateTo')
    assert @event.key?('timeTo')
  end

  test 'cache index result' do
    assert_difference -> { Dir.glob(File.join(TranslationCacheMetaDatum::CACHE_PATH, '*')).count } do
      get :index, params: { locale: 'de' }
      assert_response :ok
    end
  end

  test 'do not cache index result if cache valid' do
    FrontendCacheRebuildJob.perform_now('de')

    assert TranslationCacheMetaDatum['de'].cache_valid?

    assert_no_difference -> { Dir.glob(File.join(TranslationCacheMetaDatum::CACHE_PATH, '*')).count } do
      get :index, params: { locale: 'de' }
      assert_response :ok
    end
  end

  test 'cache index result if cache invalid' do
    FrontendCacheRebuildJob.perform_now('de')

    TranslationCacheMetaDatum.any_instance.stubs(:cache_valid?).returns(false)

    path = TranslationCacheMetaDatum['de'].cache_file_path
    backup_path = "#{path}.bak"
    FileUtils.copy(path, "#{path}.bak")
    assert_not FileUtils.uptodate?(path, [backup_path])

    assert_no_difference -> { Dir.glob(File.join(TranslationCacheMetaDatum::CACHE_PATH, '*')).count } do
      get :index, params: { locale: 'de' }
      assert_response :ok
    end

    assert FileUtils.uptodate?(path, [backup_path])
  end

end
