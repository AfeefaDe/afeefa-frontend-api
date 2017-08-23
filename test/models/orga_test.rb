require 'test_helper'

class OrgaTest < ActiveSupport::TestCase

  test 'should have tags' do
    tags = 'tag1,tag2'
    assert orga = Orga.create(tags: tags)
    json = JSON.parse(orga.to_json)
    assert_equal tags, json['tags']
    assert json.key?('supportWantedDetail')
  end

end
