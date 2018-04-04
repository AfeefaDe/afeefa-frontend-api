require 'test_helper'
require 'message_api_test_helper'

class FeedbacksControllerTest < ActionController::TestCase

  include MessageApiTestHelper

  setup do
    @message_api = mock_message_api
  end

  test 'should send general feedback via message api for default area' do
    assert_general_feedback_mail_success do |payload|
      assert_equal 'dresden', payload[:area]
    end

    message = "This is a dummy-\nmessage for the general feedback test"
    params = dummy_general_feedback_params.merge(message: message)
    assert_nil params[:area]

    post :general_feedback, params: params
    assert_response :created, response.body
  end

  test 'should send general feedback for given area' do
    assert_general_feedback_mail_success do |payload|
      assert_equal 'leipzig', payload[:area]
    end

    message = "This is a dummy-\nmessage for the general feedback test"
    params = dummy_general_feedback_params.merge(message: message, area: 'leipzig')

    post :general_feedback, params: params
    assert_response :created, response.body
  end

  test 'should send general feedback to default area for invalid area' do
    assert_general_feedback_mail_success do |payload|
      assert_equal 'dresden', payload[:area]
    end

    message = "This is a dummy-\nmessage for the general feedback test"
    params = dummy_general_feedback_params.merge(message: message, area: 'foo-bar')

    post :general_feedback, params: params
    assert_response :created, response.body
  end

  test 'should handle send general feedback error for message api error' do
    assert_general_feedback_mail_error

    message = "This is a dummy-\nmessage for the general feedback test"
    params = dummy_general_feedback_params.merge(message: message)

    post :general_feedback, params: params
    assert_response :internal_server_error, response.body
  end

  private

  def dummy_general_feedback_params(area: nil)
    {
      message: 'This is a dummy message.',
      author: 'dummy author',
      mail: 'dummy@author.com'
    }.tap do |hash|
      hash[:area] = area if area
    end
  end

end
