module DataModules::Offer
  class Offer < ApplicationRecord
    has_many :contacts, class_name: DataPlugins::Contact::Contact, as: :owner
    has_many :translation_caches, as: :cacheable, dependent: :destroy, class_name: 'TranslationCache'

    has_many :navigation_item_owners,
      class_name: DataModules::FeNavigation::FeNavigationItemOwner, as: :owner
    has_many :navigation_items, through: :navigation_item_owners

    scope :for_json, -> { }

    def self.default_includes
      [:contacts, :navigation_items]
    end

    def as_json(*args)
      {
        :id => self.id,
        :entryType => 'Offer',
        :type => 3,

        location: [],
        navigation_items: self.navigation_items.pluck(:id)
      }
    end
  end
end
