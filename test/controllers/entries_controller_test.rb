require 'test_helper'
require 'message_api_test_helper'

class EntriesControllerTest < ActionController::TestCase

  include MessageApiTestHelper

  setup do
    @message_api = mock_message_api

    @orga = create(:orga, title: 'orga.1.title', area: 'dresden', translated_locales: ['en'])
    @event = create(:event, title: 'event.1.title', area: 'dresden', hosts: [@orga])
    @event2 = create(:event, title: 'event.2.title', area: 'dresden')
    @orga2 = create(:orga, title: 'orga.2.title', area: 'bautzen')

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
    assert event = json['events'].last
    assert event.key?('dateFrom')
    assert event.key?('timeFrom')
    assert event.key?('dateTo')
    assert event.key?('timeTo')
  end

  test 'should get dresden/de' do
    get :index, params: { area: 'dresden', locale: 'de' }
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 2, json['orgas'].size
    assert_equal 2, json['events'].size
    assert_equal @orga.id, json['orgas'][0]['id']
    assert_equal @event2.hosts.first.id, json['orgas'][1]['id']
    assert_equal @event2.id, json['events'][1]['id']
  end

  test 'should get dresden/de by default' do
    get :index
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 2, json['orgas'].size
    assert_equal 2, json['events'].size
    assert_equal @orga.id, json['orgas'][0]['id']
    assert_equal @event2.hosts.first.id, json['orgas'][1]['id']
    assert_equal @event2.id, json['events'][1]['id']
  end

  test 'should get dresden/en' do
    get :index, params: { area: 'dresden', locale: 'en' }
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 2, json['orgas'].size
    assert_equal 2, json['events'].size
    assert_equal @orga.id, json['orgas'][0]['id']
    assert_equal @event2.hosts.first.id, json['orgas'][1]['id']
    assert_equal @event2.id, json['events'][1]['id']
  end

  test 'should get bautzen' do
    get :index, params: { area: 'bautzen' }
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 1, json['orgas'].size
    assert_equal 0, json['events'].size
    assert_equal @orga2.id, json['orgas'][0]['id']
  end

  test 'should fallback to dresden/de' do
    get :index, params: { area: 'frauenthal', locale: 'foo' }
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 2, json['orgas'].size
    assert_equal 2, json['events'].size
    assert_equal @orga.id, json['orgas'][0]['id']
    assert_equal @event2.hosts.first.id, json['orgas'][1]['id']
    assert_equal @event2.id, json['events'][1]['id']
  end

  test 'should create orga' do
    assert_new_entry_info_success do |payload|
      assert payload.key?(:key)
      assert_equal 'Orga via Frontend', payload[:title]
    end

    orga_params =
      JSON.parse(
        File.read(
          Rails.root.join('test', 'fixtures', 'files', 'create-orga.json')))

    assert_difference -> {
      Annotation.
        where(annotation_category: AnnotationCategory.external_entry).
        where(detail: nil).
        count
    } do
      assert_difference -> { Orga.count } do
        assert_no_difference -> { Orga.where(state: :active).count } do
          post :create, params: orga_params
          assert_response :created
        end
      end
    end
    assert_equal title = orga_params['marketentry']['name'], Orga.last.title
    assert_equal 'inactive', Orga.last.state

    assert_equal Orga.last.linked_contact, Orga.last.contacts.first
    assert_equal Orga.last.linked_contact.location, Orga.last.locations.first

    assert_equal orga_params['location']['placename'], Orga.last.linked_contact.location.title
    assert_equal orga_params['location']['street'], Orga.last.linked_contact.location.street
    assert_equal orga_params['location']['zip'], Orga.last.linked_contact.location.zip
    assert_equal orga_params['location']['city'], Orga.last.linked_contact.location.city

    assert_equal orga_params['marketentry']['web'], Orga.last.linked_contact.web
    assert_equal orga_params['marketentry']['facebook'], Orga.last.linked_contact.social_media

    assert_equal orga_params['marketentry']['speakerPublic'], Orga.last.linked_contact.contact_persons.first.name
    assert_equal orga_params['marketentry']['mail'], Orga.last.linked_contact.contact_persons.first.mail
    assert_equal orga_params['marketentry']['phone'], Orga.last.linked_contact.contact_persons.first.phone

    assert_equal 1, Annotation.where(entry: Orga.last).count
    assert_equal AnnotationCategory.external_entry, Annotation.where(entry: Orga.last).last.annotation_category

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
        assert_response :internal_server_error
        assert_match 'internal error', response.body
      end
    end
  end

  test 'should create orga with error during new entry notification' do
    assert_new_entry_info_error do |payload|
      assert payload.key?(:key)
      assert_equal 'Orga via Frontend', payload[:title]
    end

    orga_params =
      JSON.parse(
        File.read(
          Rails.root.join('test', 'fixtures', 'files', 'create-orga.json')))

    assert_difference -> {
      Annotation.
        where(annotation_category: AnnotationCategory.external_entry).
        where(detail: nil).
        count
    } do
      assert_difference -> { Orga.count } do
        assert_no_difference -> { Orga.where(state: :active).count } do
          post :create, params: orga_params
          assert_response :created
        end
      end
    end
    assert_equal title = orga_params['marketentry']['name'], Orga.last.title
    assert_equal 'inactive', Orga.last.state
    placename = orga_params['location']['placename']
    assert_equal placename, Orga.last.linked_contact.location.title
    contact_person = orga_params['marketentry']['speakerPublic']
    assert_equal contact_person, Orga.last.linked_contact.contact_persons.first.name
    assert_equal 1, Annotation.where(entry: Orga.last).count
    assert_equal AnnotationCategory.external_entry, Annotation.where(entry: Orga.last).last.annotation_category

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
        assert_response :internal_server_error
        assert_match 'internal error', response.body
      end
    end
  end

  test 'should create event' do
    assert_new_entry_info_success do |payload|
      assert_equal 'Mein neues Event', payload[:title]
    end

    event_params =
      JSON.parse(
        File.read(
          Rails.root.join('test', 'fixtures', 'files', 'create-event.json')))

    assert_difference -> { Event.unscoped.count } do
      assert_no_difference -> { Event.unscoped.where(state: :active).count } do
        post :create, params: event_params
        assert_response :created
      end
    end
    event = Event.unscoped.last
    assert_equal title = event_params['marketentry']['name'], event.title
    assert_equal 'inactive', event.state

    assert_equal event_params['location']['placename'], event.linked_contact.location.title
    assert_equal event_params['location']['street'], event.linked_contact.location.street
    assert_equal event_params['location']['zip'], event.linked_contact.location.zip
    assert_equal event_params['location']['city'], event.linked_contact.location.city

    assert_equal event_params['marketentry']['web'], event.linked_contact.web
    assert_equal event_params['marketentry']['facebook'], event.linked_contact.social_media

    assert_equal event_params['marketentry']['speakerPublic'], event.linked_contact.contact_persons.first.name
    assert_equal event_params['marketentry']['mail'], event.linked_contact.contact_persons.first.mail
    assert_equal event_params['marketentry']['phone'], event.linked_contact.contact_persons.first.phone

    Time.freeze do
      assert_difference -> { Event.unscoped.count } do
        assert_no_difference -> { Event.unscoped.where(state: :active).count } do
          post :create, params: event_params
          assert_response :created
        end
      end
      assert_match /\A#{title}_\d*/, event.title
      assert_equal 'inactive', event.state

      assert_no_difference -> { Event.unscoped.count } do
        assert_no_difference -> { Event.unscoped.where(state: :active).count } do
          post :create, params: event_params
          assert_response :unprocessable_entity
          assert_match 'bereits vergeben', response.body
        end
      end
    end

    Event.any_instance.stubs(:save).returns(false)
    assert_no_difference -> { Event.unscoped.count } do
      assert_no_difference -> { Event.unscoped.where(state: :active).count } do
        post :create, params: event_params
        assert_response :internal_server_error
        assert_match 'internal error', response.body
      end
    end
  end

  test 'should set time information for time_start and time_end at created event' do
    assert_new_entry_info_success

    event_params =
      JSON.parse(
        File.read(
          Rails.root.join('test', 'fixtures', 'files', 'create-event.json')))

    assert_difference -> { Event.unscoped.count } do
      assert_no_difference -> { Event.unscoped.where(state: :active).count } do
        post :create, params: event_params
        assert_response :created
      end
    end
    event = Event.unscoped.last
    assert_equal title = event_params['marketentry']['name'], event.title
    assert_equal 'inactive', event.state
    assert_equal event_params['marketentry']['dateFrom'], event.date_start.strftime('%Y-%m-%d')
    assert_equal event_params['marketentry']['dateTo'], event.date_end.strftime('%Y-%m-%d')
    assert_equal event_params['marketentry']['timeFrom'], event.date_start.strftime('%H:%M')
    assert_equal event_params['marketentry']['timeTo'], event.date_end.strftime('%H:%M')
    assert event.time_start?
    assert event.time_end?
  end

  test 'should set time information for time_start at created event' do
    assert_new_entry_info_success

    event_params =
      JSON.parse(
        File.read(
          Rails.root.join('test', 'fixtures', 'files', 'create-event.json')))
    event_params['marketentry']['timeTo'] = '00:00'

    assert_difference -> { Event.unscoped.count } do
      assert_no_difference -> { Event.unscoped.where(state: :active).count } do
        post :create, params: event_params
        assert_response :created
      end
    end
    event = Event.unscoped.last
    assert_equal title = event_params['marketentry']['name'], event.title
    assert_equal 'inactive', event.state
    assert_equal event_params['marketentry']['dateFrom'], event.date_start.strftime('%Y-%m-%d')
    assert_equal event_params['marketentry']['dateTo'], event.date_end.strftime('%Y-%m-%d')
    assert_equal event_params['marketentry']['timeFrom'], event.date_start.strftime('%H:%M')
    assert_equal event_params['marketentry']['timeTo'], event.date_end.strftime('%H:%M')
    assert event.time_start?
    assert_not event.time_end?
  end

  test 'should set time information for time_end at created event' do
    assert_new_entry_info_success

    event_params =
      JSON.parse(
        File.read(
          Rails.root.join('test', 'fixtures', 'files', 'create-event.json')))
    event_params['marketentry']['timeFrom'] = '00:00'

    assert_difference -> { Event.unscoped.count } do
      assert_no_difference -> { Event.unscoped.where(state: :active).count } do
        post :create, params: event_params
        assert_response :created
      end
    end
    event = Event.unscoped.last
    assert_equal title = event_params['marketentry']['name'], event.title
    assert_equal 'inactive', event.state
    assert_equal event_params['marketentry']['dateFrom'], event.date_start.strftime('%Y-%m-%d')
    assert_equal event_params['marketentry']['dateTo'], event.date_end.strftime('%Y-%m-%d')
    assert_equal event_params['marketentry']['timeFrom'], event.date_start.strftime('%H:%M')
    assert_equal event_params['marketentry']['timeTo'], event.date_end.strftime('%H:%M')
    assert_not event.time_start?
    assert event.time_end?
  end

  test 'should created event without dateTo and timeTo' do
    assert_new_entry_info_success

    event_params =
      JSON.parse(
        File.read(
          Rails.root.join('test', 'fixtures', 'files', 'create-event.json')))
    event_params['marketentry']['dateTo'] = nil
    event_params['marketentry']['timeTo'] = nil

    assert_difference -> { Event.unscoped.count } do
      assert_no_difference -> { Event.unscoped.where(state: :active).count } do
        post :create, params: event_params
        assert_response :created
      end
    end
    event = Event.unscoped.last
    assert_equal title = event_params['marketentry']['name'], event.title
    assert_equal 'inactive', event.state
    assert_equal event_params['marketentry']['dateFrom'], event.date_start.strftime('%Y-%m-%d')
    assert_equal event_params['marketentry']['timeFrom'], event.date_start.strftime('%H:%M')
    assert_nil event.date_end
    assert event.time_start?
    assert_not event.time_end?
  end

  test 'should created event without dateTo but timeTo' do
    assert_new_entry_info_success

    event_params =
      JSON.parse(
        File.read(
          Rails.root.join('test', 'fixtures', 'files', 'create-event.json')))
    event_params['marketentry']['dateTo'] = nil
    assert event_params['marketentry']['timeTo']

    assert_difference -> { Event.unscoped.count } do
      assert_no_difference -> { Event.unscoped.where(state: :active).count } do
        post :create, params: event_params
        assert_response :created
      end
    end
    event = Event.unscoped.last
    assert_equal title = event_params['marketentry']['name'], event.title
    assert_equal 'inactive', event.state
    assert_equal event_params['marketentry']['dateFrom'], event.date_start.strftime('%Y-%m-%d')
    assert_equal event_params['marketentry']['timeFrom'], event.date_start.strftime('%H:%M')
    assert_equal event_params['marketentry']['dateFrom'], event.date_end.strftime('%Y-%m-%d')
    assert_equal event_params['marketentry']['timeTo'], event.date_end.strftime('%H:%M')
    assert event.time_start?
    assert event.time_end?
  end

  test 'should contact orga' do
    assert_contact_entry_mail_success

    orga = Orga.last
    contact = DataPlugins::Contact::Contact.create!(owner: orga)
    contact_person = DataPlugins::Contact::ContactPerson.create(name: 'Max Mustermann', mail: 'max@mustermann.foo')
    contact.contact_persons << contact_person
    assert DataPlugins::Contact::Contact.where(owner: orga).any?

    post :contact_entry, params: {
      type: 'orgas',
      id: orga.id,
      message: 'This is a dummy message.',
      author: 'dummy author',
      mail: 'dummy@author.com',
      phone: '01815'
    }
    assert_response :created
  end

  test 'should handle message api error on contact orga' do
    assert_contact_entry_mail_error

    orga = Orga.last
    contact = DataPlugins::Contact::Contact.create!(owner: orga)
    contact_person = DataPlugins::Contact::ContactPerson.create(name: 'Max Mustermann', mail: 'max@mustermann.foo')
    contact.contact_persons << contact_person
    assert DataPlugins::Contact::Contact.where(owner: orga).any?

    post :contact_entry, params: {
      type: 'orgas',
      id: orga.id,
      message: 'This is a dummy message.',
      author: 'dummy author',
      mail: 'dummy@author.com',
      phone: '01815'
    }
    assert_response :internal_server_error
    assert_equal 'error during sending message for contact entry: response error', response.body
  end

  test 'should raise not found if orga has no contact data' do
    orga = Orga.last
    DataPlugins::Contact::Contact.where(owner: orga).destroy_all
    assert DataPlugins::Contact::Contact.where(owner: orga).blank?

    assert_raise ActiveRecord::RecordNotFound do
      post :contact_entry, params: {
        type: 'orgas',
        id: orga.id,
        message: 'This is a dummy message.',
        author: 'dummy author',
        mail: 'dummy@author.com',
        phone: '01815'
      }
    end
  end

  test 'should create feedback for orga with message api success' do
    assert_feedback_entry_mail_success

    orga = Orga.last
    message = "This is a dummy-\nmessage for the feedback test"
    params = dummy_feedback_entry_params(orga).merge(message: message)

    assert_difference -> { Annotation.count } do
      post :feedback_entry, params: params
      assert_response :created, response.body
    end
    assert annotation = Annotation.last
    assert_equal orga, annotation.entry
    assert_equal AnnotationCategory.external_feedback, annotation.annotation_category
    expect_annotation_detail(annotation, params)
  end

  test 'should create feedback for orga with message api error' do
    assert_feedback_entry_mail_error

    orga = Orga.last
    message = "This is a dummy-\nmessage for the feedback test"
    params = dummy_feedback_entry_params(orga).merge(message: message)

    assert_difference -> { Annotation.count } do
      post :feedback_entry, params: params
      assert_response :created, response.body
    end
    assert annotation = Annotation.last
    assert_equal orga, annotation.entry
    assert_equal AnnotationCategory.external_feedback, annotation.annotation_category
    expect_annotation_detail(annotation, params)
  end

  test 'should handle create feedback error for orga with message api success' do
    assert_feedback_entry_mail_success
    Rails.logger.expects(:warn).with do |message|
      assert_match 'could not create annotation', message
      true
    end

    orga = Orga.last
    message = "This is a dummy-\nmessage for the feedback test"
    params = dummy_feedback_entry_params(orga).merge(message: message)

    Annotation.any_instance.stubs(:save).returns(false)
    assert_no_difference -> { Annotation.count } do
      post :feedback_entry, params: params
      assert_response :internal_server_error, response.body
    end
  end

  test 'should handle create feedback error for orga with message api error' do
    assert_feedback_entry_mail_error
    Rails.logger.unstub(:warn)
    Rails.logger.expects(:warn).with do |message|
      unless message =~ /could not create annotation/
        assert_equal 'error during sending message for feedback entry: response error', message
      end
      true
    end.twice

    orga = Orga.last
    message = "This is a dummy-\nmessage for the feedback test"
    params = dummy_feedback_entry_params(orga).merge(message: message)

    Annotation.any_instance.stubs(:save).returns(false)
    assert_no_difference -> { Annotation.count } do
      post :feedback_entry, params: params
      assert_response :internal_server_error, response.body
    end
  end

  private

  def expect_annotation_detail(annotation, params)
    expected_detail =
      "#{params[:message]}\n#{params[:author]} " +
        "(#{[params[:mail], params[:phone]].join(', ')})"
    assert_equal expected_detail, annotation.detail
  end

  def dummy_contact_entry_params(model)
    {
      type: model.class.to_s.underscore.pluralize,
      id: model.id,
      message: 'This is a dummy message.',
      author: 'dummy author',
      mail: 'dummy@author.com',
      phone: '01815'
    }
  end

  def dummy_feedback_entry_params(model)
    dummy_contact_entry_params(model)
  end

end
