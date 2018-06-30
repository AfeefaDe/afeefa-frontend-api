module DataModules::FeNavigation
  class FeNavigation < ApplicationRecord
    has_many :navigation_items,
      class_name: DataModules::FeNavigation::FeNavigationItem, foreign_key: 'navigation_id'
  end
end
