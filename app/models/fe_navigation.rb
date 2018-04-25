class FeNavigation < ApplicationRecord
  # ASSOCIATIONS
  has_many :navigation_items,
    class_name: FeNavigationItem, foreign_key: 'navigation_id', dependent: :destroy

  scope :by_area, -> (area) { where(area: area) }

end
