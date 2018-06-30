module DataPlugins::Facet
  class FacetItem < ApplicationRecord

    belongs_to :facet
    has_many :sub_items, class_name: DataPlugins::Facet::FacetItem, foreign_key: :parent_id
    has_many :translation_caches, as: :cacheable, dependent: :destroy, class_name: 'TranslationCache'

    def as_json(*args)
      json = {
        id: self.id
      }
      unless self.parent_id
        json[:sub_items] = sub_items
      end
      json
    end
  end
end
