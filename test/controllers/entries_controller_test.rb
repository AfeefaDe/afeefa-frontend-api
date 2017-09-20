require 'test_helper'

class EntriesControllerTest < ActionController::TestCase

  setup do
    orga = Orga.new(state: :active, title: 'orga xyz')
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
