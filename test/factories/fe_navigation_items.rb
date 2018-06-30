FactoryGirl.define do

  factory :fe_navigation_item, class: DataModules::FeNavigation::FeNavigationItem do
    title {"title#{rand(0..1000)}"}
    association :navigation, factory: :fe_navigation

    factory :fe_navigation_item_with_sub_items do
      transient do
        sub_items_count 2
      end
      after(:create) do |navigation_item, evaluator|
        create_list(:fe_navigation_item, evaluator.sub_items_count, navigation: navigation_item.navigation, parent_id: navigation_item.id)
      end
    end
  end

end
