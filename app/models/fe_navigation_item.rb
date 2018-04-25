class FeNavigationItem < ApplicationRecord
  # ASSOCIATIONS
  belongs_to :navigation, class_name: FeNavigation
  belongs_to :parent, class_name: FeNavigationItem, optional: true
  has_many :sub_items, class_name: FeNavigationItem, foreign_key: :parent_id, dependent: :destroy

  has_many :navigation_item_owners,
    class_name: FeNavigationItemOwner, foreign_key: :navigation_item_id, dependent: :destroy

  def owner_hash
    navigation_item_owners.map { |data| { id: data.owner_id, type: data.owner_type.underscore.pluralize } }
  end

  def area
    navigation.area
  end

  def as_json(options = {})
    super.
      # # reject { |key, _value| key.to_s.in?(['title', 'created_at', 'updated_at']) }.
      slice('id', 'title', 'color').
      merge(
        sub_items: sub_items.map { |x| x.as_json(options) },
        owners: owner_hash
      )
  end
end
