require 'test_helper'

class EntriesControllerTest < ActionController::TestCase

  test 'get filter title and description' do
    orga = Orga.new(state: :active)
    assert orga.save(validate: false)
    event = Event.new(state: :active)
    assert event.save(validate: false)
    location = event.locations.new
    assert location.save(validate: false)
    event2 = Event.new(state: :active)
    assert event2.save(validate: false)

    get :index, params: { locale: 'de' }
    json = JSON.parse(response.body)
    assert_response :ok
    assert json['marketentries'].last.key?('dateFrom')
    assert json['marketentries'].last.key?('timeFrom')
    assert json['marketentries'].last.key?('dateTo')
    assert json['marketentries'].last.key?('timeTo')
  end

end
