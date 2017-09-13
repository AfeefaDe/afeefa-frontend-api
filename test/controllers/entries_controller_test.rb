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
    assert_equal 3, json['marketentries'].size
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

  test 'should create orga' do
    orga_params = { type: 'orga', title: 'special new orga' }

    assert_difference -> { Orga.count } do
      assert_no_difference -> { Orga.where(state: :active).count } do
        post :create, params: orga_params
        assert_response :created
      end
    end
    assert_equal orga_params[:title], Orga.last.title
    assert_equal 'inactive', Orga.last.state

    Time.freeze do
      assert_difference -> { Orga.count } do
        assert_no_difference -> { Orga.where(state: :active).count } do
          post :create, params: orga_params
          assert_response :created
        end
      end
      assert_match /\A#{orga_params[:title]}_\d*/, Orga.last.title
      assert_equal 'inactive', Orga.last.state

      assert_no_difference -> { Orga.count } do
        assert_no_difference -> { Orga.where(state: :active).count } do
          post :create, params: orga_params
          assert_response :unprocessable_entity
          assert_match 'bereits vergeben', response.body
        end
      end
    end

    Orga.any_instance.stubs(:save).returns(false)
    assert_no_difference -> { Orga.count } do
      assert_no_difference -> { Orga.where(state: :active).count } do
        post :create, params: orga_params
        assert_response :unprocessable_entity
        assert_match 'internal error', response.body
      end
    end
  end

  test 'should create event' do
    event_params = {
      type: 'event', title: 'special new event',
      date_start: Time.zone.parse("01.01.#{1.year.from_now.year} 10:00")
    }

    assert_difference -> { Event.count } do
      assert_no_difference -> { Event.where(state: :active).count } do
        post :create, params: event_params
        assert_response :created
      end
    end
    assert_equal event_params[:title], Event.last.title
    assert_equal 'inactive', Event.last.state

    Time.freeze do
      assert_difference -> { Event.count } do
        assert_no_difference -> { Event.where(state: :active).count } do
          post :create, params: event_params
          assert_response :created
        end
      end
      assert_match /\A#{event_params[:title]}_\d*/, Event.last.title
      assert_equal 'inactive', Event.last.state

      assert_no_difference -> { Event.count } do
        assert_no_difference -> { Event.where(state: :active).count } do
          post :create, params: event_params
          assert_response :unprocessable_entity
          assert_match 'bereits vergeben', response.body
        end
      end
    end

    Event.any_instance.stubs(:save).returns(false)
    assert_no_difference -> { Event.count } do
      assert_no_difference -> { Event.where(state: :active).count } do
        post :create, params: event_params
        assert_response :unprocessable_entity
        assert_match 'internal error', response.body
      end
    end
  end

end
