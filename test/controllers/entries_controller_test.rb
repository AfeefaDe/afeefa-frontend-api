require 'test_helper'

class EntriesControllerTest < ActionController::TestCase

  setup do
    orga = Orga.new(state: :active)
    assert orga.save(validate: false)
    @event = Event.new(state: :active)
    assert @event.save(validate: false)
    location = @event.locations.new
    assert location.save(validate: false)
    event2 = Event.new(state: :active)
    assert event2.save(validate: false)

    FileUtils.rm_rf(TranslationCacheMetaDatum::CACHE_PATH)
    TranslationCacheMetaDatum.delete_all

    init_translation_cache('de')
  end

  test 'get filter title and description' do
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

end
