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

  it 'should trigger cache builder on rebuild all request' do
    CacheBuilder.any_instance.expects(:build_all)

    perform_enqueued_jobs do
      get :update, params: { token: Settings.changes.webhook_api_token }
    end
  end

  it 'should trigger cache builder on entry translated request' do
    CacheBuilder.any_instance.expects(:translate_entry).with('orga', '123', 'fr')

    perform_enqueued_jobs do
      get :update, params: {
        token: Settings.changes.webhook_api_token,
        type: 'orga',
        id: 123,
        locale: 'fr'
      }
    end
  end

  it 'should trigger cache builder on entry update request' do
    CacheBuilder.any_instance.expects(:update_entry).with('orga', '123')

    perform_enqueued_jobs do
        get :update, params: {
        token: Settings.changes.webhook_api_token,
        type: 'orga',
        id: 123
      }
    end
  end

  it 'should trigger cache builder on entry delete request' do
    CacheBuilder.any_instance.expects(:remove_entry).with('buxtehude', 'event', '123')

    perform_enqueued_jobs do
      get :update, params: {
        token: Settings.changes.webhook_api_token,
        area: 'buxtehude',
        type: 'event',
        id: 123,
        deleted: true
      }
    end
  end

  it 'should trigger cache builder on entry delete request without area' do
    CacheBuilder.any_instance.expects(:remove_entry).with(nil, 'facet_item', '123')

    perform_enqueued_jobs do
      get :update, params: {
        token: Settings.changes.webhook_api_token,
        type: 'facet_item',
        id: 123,
        deleted: true
      }
    end
  end

  private

  def cache_builder
    @cache_builder ||= CacheBuilder.new
  end

end
