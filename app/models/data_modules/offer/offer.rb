module DataModules::Offer
  class Offer < ApplicationRecord
    include Entry

    has_many :offer_owners, class_name: DataModules::Offer::OfferOwner, dependent: :destroy
    has_many :owners, through: :offer_owners, source: :actor

    # entry attributes that do not exist for offer but
    # are expected by included entry
    attr_accessor :parent_orga
    attr_accessor :certified_sfr
    attr_accessor :legacy_entry_id
    attr_accessor :media_url
    attr_accessor :media_type
    attr_accessor :support_wanted
    attr_accessor :support_wanted_detail
    attr_accessor :tags

    scope :for_json, -> { }

    after_initialize do |entry|
      entry.type = 3
      entry.entry_type = 'Offer'
      entry.media_url = entry.image_url
      entry.media_type = entry.image_url ? 'image' : nil
      entry.support_wanted = false
      entry.tags = ''
    end

    def self.default_includes
      [
        :category,
        :sub_category,
        :linked_contact,
        :navigation_items,
        linked_contact: [:contact_persons, :location]
      ]
    end

    def as_json(*args)
      json = super

      json[:parentOrgaId] = owners.present? ? owners.first.id : nil

      json
    end
  end
end
