module DataModules::Offer
  class Offer < ApplicationRecord
    include Entry

    has_many :offer_owners, class_name: DataModules::Offer::OfferOwner, dependent: :destroy
    has_many :owners, through: :offer_owners, source: :actor

    # entry attributes that do not exist for offer but
    # are expected by included entry
    attr_accessor :certified_sfr
    attr_accessor :legacy_entry_id
    attr_accessor :media_url
    attr_accessor :media_type
    attr_accessor :support_wanted
    attr_accessor :support_wanted_detail
    attr_accessor :tags

    scope :active, -> { where(active: true) }
    scope :for_json, -> { active }

    after_initialize do |entry|
      entry.type = 1
      entry.entry_type = 'Offer'
      entry.media_url = entry.image_url
      entry.media_type = entry.image_url ? 'image' : nil
      entry.support_wanted = false
      entry.tags = ''
    end

    @c = self.default_includes
    def self.default_includes
      @c + %i(owners)
    end

    def as_json(*args)
      json = super

      json[:parentOrgaId] = owners.present? ? owners.first.id : nil

      json
    end
  end
end
