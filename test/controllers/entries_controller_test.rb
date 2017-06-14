require 'test_helper'

class EntriesControllerTest < ActionController::TestCase

  test 'get index' do
    orga = Orga.new(state: :active)
    orga.save!(validate: false)
    event = Event.new(state: :active, date_start: 5.days.from_now)
    event.save!(validate: false)
    location = event.locations.new
    location.save!(validate: false)
    event2 = Event.new(state: :active, date_start: 5.days.from_now)
    event2.save!(validate: false)

    get :index, params: { locale: 'de' }
    json = JSON.parse(response.body)
    assert_response :ok

    json = JSON.parse(response.body)
    assert_equal 4, json['marketentries'].size
    assert @event = json['marketentries'].last
    assert @event.key?('dateFrom')
    assert @event.key?('timeFrom')
    assert @event.key?('dateTo')
    assert @event.key?('timeTo')
  end

  test 'fail for unsupported locale' do
    exception = assert_raise do
      get :index, params: { locale: 'foo' }
    end
    assert_equal 'locale is not supported', exception.message
  end

  test 'cache index result' do
    assert_difference -> { Dir.glob(File.join(TranslationCacheMetaDatum::CACHE_PATH, '*')).count } do
      get :index, params: { locale: 'de' }
      assert_response :ok
    end
  end

  test 'get de by default' do
    orga = Orga.new(state: :active)
    assert orga.save(validate: false)
    event = Event.new(state: :active, date_start: 5.days.from_now)
    assert event.save(validate: false)
    location = event.locations.new
    assert location.save(validate: false)
    event2 = Event.new(state: :active, date_start: 5.days.from_now)
    assert event2.save(validate: false)

    get :index
    json = JSON.parse(response.body)
    assert_response :ok
    assert json['marketentries'].last.key?('dateFrom')
    assert json['marketentries'].last.key?('timeFrom')
    assert json['marketentries'].last.key?('dateTo')
    assert json['marketentries'].last.key?('timeTo')
  end

end
