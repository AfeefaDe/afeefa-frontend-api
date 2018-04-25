FactoryGirl.define do
  factory :fe_navigation_item do
    title 'soccer'
    navigation_id { create(:fe_navigation).id }

    factory :sub_fe_navigation_item do
      parent_id { create(:fe_navigation_item).id }
    end
  end
end
