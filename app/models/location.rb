class Location < ApplicationRecord

  belongs_to :orgas, foreign_key: 'locatable_id'

  attr_accessor :openingHours

  def as_json(*args)
    {
      :id => self.id,
      :arrival => self.directions,
      :city => self.city,
      :lat => self.lat,
      :lon => self.lon,
      :openingHours => self.openingHours || '',
      :placename => self.placename,
      :street => self.street,
      :zip => self.zip
    }
  end
end
