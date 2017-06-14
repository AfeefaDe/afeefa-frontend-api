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
    assert json['marketentries'].last.key?('dateFrom')
    assert json['marketentries'].last.key?('timeFrom')
    assert json['marketentries'].last.key?('dateTo')
    assert json['marketentries'].last.key?('timeTo')
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
