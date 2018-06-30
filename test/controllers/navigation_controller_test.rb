require 'test_helper'

class NavigationControllerTest < ActionController::TestCase

  setup do
    @navigation_dd = create(:fe_navigation_with_items_and_sub_items, area: 'dresden')
    @navigation_bz = create(:fe_navigation_with_items_and_sub_items, area: 'bautzen')
    cache_builder = CacheBuilder.new
    cache_builder.build_all
  end

  test 'should get navigation' do
    get :index, params: { area: 'dresden' }
    assert_response :ok
    json = JSON.parse(response.body)
    assert category = json.last
    assert category.key?('id')
    assert category.key?('sub_items')
    assert_equal 2, category['sub_items'].count
  end

  test 'should get dresden/de' do
    get :index, params: { area: 'dresden' }
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 2, json.size
    assert_equal @navigation_dd.navigation_items.first.id, json[0]['id']
  end

  test 'should get dresden by default' do
    get :index
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 2, json.size
    assert_equal @navigation_dd.navigation_items.first.id, json[0]['id']
  end

  test 'should get bautzen' do
    get :index, params: { area: 'bautzen' }
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 2, json.size
    assert_equal @navigation_bz.navigation_items.first.id, json[0]['id']
  end

  test 'should fallback to dresden/de' do
    get :index, params: { area: 'frauenthal' }
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 2, json.size
    assert_equal @navigation_dd.navigation_items.first.id, json[0]['id']
  end

end
