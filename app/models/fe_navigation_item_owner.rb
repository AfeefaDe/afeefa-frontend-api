class FeNavigationItemOwner < ApplicationRecord

  belongs_to :navigation_item, class_name: FeNavigationItem
  belongs_to :owner, polymorphic: true

end
