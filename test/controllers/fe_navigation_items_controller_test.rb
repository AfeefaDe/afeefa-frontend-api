require 'test_helper'

class FeNavigationItemsControllerTest < ActionController::TestCase

  setup do
    assert navigation = create(:fe_navigation, area: 'dresden')

    assert navigation_item = create(:fe_navigation_item, title: 'general', navigation: navigation)
    assert sub_navigation_item =
      create(:fe_navigation_item, title: 'wifi', parent_id: navigation_item.id, navigation: navigation)
    assert sub_navigation_item_2 =
      create(:fe_navigation_item, title: 'other', parent_id: navigation_item.id, navigation: navigation)
    assert navigation2 = create(:fe_navigation, area: 'bautzen')
    assert navigation_item2 = create(:fe_navigation_item, title: 'swimming', navigation: navigation2)

    assert orga = Orga.create(title: 'foo')
    assert FeNavigationItemOwner.create(navigation_item: navigation_item, owner: orga)
    assert FeNavigationItemOwner.create(navigation_item: sub_navigation_item_2, owner: orga)

    # test data from backend
    x = FeNavigationItemOwner.new(navigation_item: sub_navigation_item, owner_id: 3, owner_type: 'Foo')
    assert x.save(validate: false)
  end

  test 'should get navigation items' do
    get :index, params: { area: 'dresden', locale: 'de' }
    assert_response :ok
    json = JSON.parse(response.body)
    assert navigation_item = json['fe_navigation_items'].last
    assert navigation_item.key?('title')
    assert navigation_item.key?('id')
    assert navigation_item.key?('sub_items')
    assert_equal 2, navigation_item['sub_items'].count
  end

  test 'should get dresden/de' do
    get :index, params: { area: 'dresden', locale: 'de' }
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 1, json['fe_navigation_items'].size
    assert_equal 'general', json['fe_navigation_items'][0]['title']
  end

  test 'should get dresden/de by default' do
    get :index
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 1, json['fe_navigation_items'].size
    assert_equal 'general', json['fe_navigation_items'][0]['title']
  end

  test 'should get dresden/en' do
    get :index, params: { area: 'dresden', locale: 'en' }
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 1, json['fe_navigation_items'].size
    assert_equal 'general', json['fe_navigation_items'][0]['title']
  end

  test 'should get bautzen' do
    get :index, params: { area: 'bautzen' }
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 1, json['fe_navigation_items'].size
    assert_equal 'swimming', json['fe_navigation_items'][0]['title']
  end

  test 'should fallback to dresden/de' do
    get :index, params: { area: 'frauenthal', locale: 'foo' }
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 1, json['fe_navigation_items'].size
    assert_equal 'general', json['fe_navigation_items'][0]['title']
  end

end
