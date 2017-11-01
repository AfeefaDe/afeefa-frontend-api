require 'test_helper'

class CategoriesControllerTest < ActionController::TestCase

  setup do
    assert category = create(:category, title: 'general', area: 'dresden')
    assert sub_category =
      create(:category, title: 'wifi', area: 'dresden', parent_id: category.id)
    assert sub_category_2 =
      create(:category, title: 'other', area: 'dresden', parent_id: category.id)
    assert category2 = create(:category, title: 'swimming', area: 'bautzen')
  end

  test 'should get categories' do
    get :index, params: { area: 'dresden', locale: 'de' }
    assert_response :ok
    json = JSON.parse(response.body)
    assert category = json['categories'].last
    assert category.key?('name')
    assert category.key?('id')
    assert category.key?('sub')
    assert_equal 2, category['sub'].count
  end

  test 'should get dresden/de' do
    get :index, params: { area: 'dresden', locale: 'de' }
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 1, json['categories'].size
    assert_equal 'general', json['categories'][0]['name']
  end

  test 'should get dresden/de by default' do
    get :index
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 1, json['categories'].size
    assert_equal 'general', json['categories'][0]['name']
  end

  test 'should get dresden/en' do
    get :index, params: { area: 'dresden', locale: 'en' }
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 1, json['categories'].size
    assert_equal 'general', json['categories'][0]['name']
  end

  test 'should get bautzen' do
    get :index, params: { area: 'bautzen' }
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 1, json['categories'].size
    assert_equal 'swimming', json['categories'][0]['name']
  end

  test 'should fallback to dresden/de' do
    get :index, params: { area: 'frauenthal', locale: 'foo' }
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 1, json['categories'].size
    assert_equal 'general', json['categories'][0]['name']
  end

end
