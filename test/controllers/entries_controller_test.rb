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
    orga_params =
      JSON.parse(
        File.read(
          Rails.root.join('test', 'fixtures', 'files', 'create-orga.json')))

    assert_difference -> { Orga.count } do
      assert_no_difference -> { Orga.where(state: :active).count } do
        post :create, params: orga_params
        assert_response :created
      end
    end
    assert_equal title = orga_params['marketentry']['name'], Orga.last.title
    assert_equal 'inactive', Orga.last.state
    placename = orga_params['location']['placename']
    assert_equal placename, Orga.last.locations.last.placename
    contact_person = orga_params['marketentry']['speakerPublic']
    assert_equal contact_person, Orga.last.contact_infos.last.contact_person

    Time.freeze do
      assert_difference -> { Orga.count } do
        assert_no_difference -> { Orga.where(state: :active).count } do
          post :create, params: orga_params
          assert_response :created
        end
      end
      assert_match /\A#{title}_\d*/, Orga.last.title
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
    event_params =
      JSON.parse(
        File.read(
          Rails.root.join('test', 'fixtures', 'files', 'create-event.json')))

    assert_difference -> { Event.count } do
      assert_no_difference -> { Event.where(state: :active).count } do
        post :create, params: event_params
        assert_response :created
      end
    end
    assert_equal title = event_params['marketentry']['name'], Event.last.title
    assert_equal 'inactive', Event.last.state
    placename = event_params['location']['placename']
    assert_equal placename, Event.last.locations.last.placename
    contact_person = event_params['marketentry']['speakerPublic']
    assert_equal contact_person, Event.last.contact_infos.last.contact_person

    Time.freeze do
      assert_difference -> { Event.count } do
        assert_no_difference -> { Event.where(state: :active).count } do
          post :create, params: event_params
          assert_response :created
        end
      end
      assert_match /\A#{title}_\d*/, Event.last.title
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
