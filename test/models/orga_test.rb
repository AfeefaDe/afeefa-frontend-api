require 'test_helper'

class OrgaTest < ActiveSupport::TestCase

  test 'should have tags' do
    tags = 'tag1,tag2'
    assert orga = Orga.create(tags: tags)
    json = JSON.parse(orga.to_json)
    assert_equal tags, json['tags']
    assert json.key?('supportWantedDetail')
  end

  test 'not save entry with duplicated title' do
    assert orga = Orga.create(title: '123')

    result = Orga.create_via_frontend(model_atrtibtues: { title: orga.title })
    assert_not result[:success]
    assert new_orga = result[:model]
    assert_equal ['ist bereits vergeben'], new_orga.errors[:title]
  end

end
