module DataModules::FeNavigation
  class FeNavigationItem < ApplicationRecord

    belongs_to :navigation, class_name: DataModules::FeNavigation::FeNavigation
    belongs_to :parent, class_name: FeNavigationItem, optional: true
    has_many :sub_items, class_name: FeNavigationItem, foreign_key: :parent_id
    has_many :translation_caches, as: :cacheable, dependent: :destroy, class_name: 'TranslationCache'

    scope :by_area, -> (area) {
      joins(:navigation).
      where('fe_navigations.area = ?', area)
    }

    def area
      navigation.area
    end

    def as_json(*args)
      json = {
        id: self.id,
        icon: self.icon
      }
      unless self.parent_id
        json[:color] = self.color
        json[:sub_items] = sub_items
      end
      json
    end
  end
end
