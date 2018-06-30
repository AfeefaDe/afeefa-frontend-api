module DataPlugins::Facet
  class Facet < ApplicationRecord

    has_many :facet_items

    def as_json(*args)
      {
        id: self.id,
        title: self.title,
        color: self.color,
        facet_items: facet_items.where(parent_id: nil)
      }
    end
  end
end
