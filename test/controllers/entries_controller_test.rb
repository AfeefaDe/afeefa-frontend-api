require 'test_helper'

class EntriesControllerTest < ActionController::TestCase

  setup do
    orga = create(:orga, title: 'orga.1.title', area: 'dresden', translated_locales: ['en'])
    @event = create(:event, title: 'event.1.title', area: 'dresden', parent_orga: orga)
    event2 = create(:event, title: 'event.2.title', area: 'dresden')
    orga2 = create(:orga, title: 'orga.2.title', area: 'bautzen')

    silence_warnings do
      @old_locales = Translation::TRANSLATABLE_LOCALES
      Translation.const_set(:TRANSLATABLE_LOCALES, ['en'])
    end

    cache_builder = CacheBuilder.new
    cache_builder.purge
    cache_builder.build_all
  end

  teardown do
    silence_warnings do
      Translation.const_set(:TRANSLATABLE_LOCALES, @old_locales)
    end
  end

  test 'should get event' do
    get :index, params: { area: 'dresden', locale: 'de' }
    assert_response :ok
    json = JSON.parse(response.body)
    assert event = json['marketentries'].last
    assert event.key?('dateFrom')
    assert event.key?('timeFrom')
    assert event.key?('dateTo')
    assert event.key?('timeTo')
  end

  test 'should get dresden/de' do
    get :index, params: { area: 'dresden', locale: 'de' }
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 4, json['marketentries'].size
    assert_equal 'orga.1.title', json['marketentries'][0]['name']
    assert_equal 'event.2.title', json['marketentries'][3]['name']
  end

  test 'should get dresden/de by default' do
    get :index
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 4, json['marketentries'].size
    assert_equal 'orga.1.title', json['marketentries'][0]['name']
    assert_equal 'event.2.title', json['marketentries'][3]['name']
  end

  test 'should get dresden/en' do
    get :index, params: { area: 'dresden', locale: 'en' }
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 4, json['marketentries'].size
    assert_equal 'orga.1.title_en', json['marketentries'][0]['name']
    assert_equal 'event.2.title', json['marketentries'][3]['name']
  end

  test 'should get bautzen' do
    get :index, params: { area: 'bautzen' }
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 1, json['marketentries'].size
    assert_equal 'orga.2.title', json['marketentries'][0]['name']
  end

  test 'should fallback to dresden/de' do
    get :index, params: { area: 'frauenthal', locale: 'foo' }
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 4, json['marketentries'].size
    assert_equal 'orga.1.title', json['marketentries'][0]['name']
    assert_equal 'event.2.title', json['marketentries'][3]['name']
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
