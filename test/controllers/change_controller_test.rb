require "test_helper"

include ActiveJob::TestHelper
Rails.application.config.active_job.queue_adapter = :test

class ChangeControllerTest < ActionController::TestCase
  it 'should get status 401 for missing webhook token' do
    get :update
    assert_response :unauthorized
  end

  it 'should get status 401 for wrong webhook token' do
    get :update, params: { token: 1234 }
    assert_response :unauthorized
  end

  it 'should get status 200 for valid webhook token' do
    @controller.expects(:update)
    get :update, params: { token: Settings.changes.webhook_api_token }
    assert_response :no_content
  end

  it 'should trigger cache rebuild job' do
    assert_enqueued_jobs 1, only: FrontendCacheRebuildJob do
      get :update, params: { token: Settings.changes.webhook_api_token }
    end
  end
end
