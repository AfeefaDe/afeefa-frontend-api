module MessageApiTestHelper
  def mock_message_api
    message_api = mock()
    MessageApi::Client.stubs(:http_client).returns(message_api)
    message_api
  end

  def mock_response_success(status: 201)
    response = mock()
    response.stubs(:status).returns(status || 201)
    response
  end

  def mock_response_error(status: 500, body: nil)
    response = mock()
    response.stubs(:status).returns(status || 500)
    response.stubs(:body).returns(body || 'response error')
    response
  end

  def assert_new_entry_info_success(message_api: nil, &block)
    message_api ||= mock_message_api
    message_api.expects(:send_new_entry_info).with do |payload|
      # TODO: DO assertions for params here
      yield(payload) if block_given?
      true
    end.returns(message_api_response = mock_response_success)
    message_api_response.expects(:body).never
    Rails.logger.expects(:warn).never
  end

  def assert_new_entry_info_error(message_api: nil, &block)
    message_api ||= mock_message_api
    message_api.expects(:send_new_entry_info).with do |payload|
      yield(payload) if block_given?
      true
    end.returns(message_api_response = mock_response_error)
    expected_body = message_api_response.body
    message_api_response.expects(:body).returns(expected_body)
    Rails.logger.expects(:warn)
  end

  def assert_contact_entry_mail_success(message_api: nil, &block)
    message_api ||= mock_message_api
    message_api.expects(:send_contact_mail).with do |payload|
      yield(payload) if block_given?
      true
    end.returns(message_api_response = mock_response_success)
    message_api_response.expects(:body).never
    Rails.logger.expects(:warn).never
  end

  def assert_contact_entry_mail_error(message_api: nil, &block)
    message_api ||= mock_message_api
    message_api.expects(:send_contact_mail).with do |payload|
      yield(payload) if block_given?
      true
    end.returns(message_api_response = mock_response_error)
    expected_body = message_api_response.body
    message_api_response.expects(:body).returns(expected_body)
    Rails.logger.expects(:warn)
  end
end
