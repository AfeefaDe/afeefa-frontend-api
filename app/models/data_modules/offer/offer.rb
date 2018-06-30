module DataModules::Offer
  class Offer < ApplicationRecord
    has_many :translation_caches, as: :cacheable, dependent: :destroy, class_name: 'TranslationCache'

    scope :for_json, -> { }

    def self.default_includes
      []
    end

    def as_json(*args)
      {
        :id => self.id,
        :entryType => 'Offer',
        :type => 3
      }
    end
  end
end
