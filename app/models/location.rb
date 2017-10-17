class Location < ApplicationRecord

  belongs_to :locatable, polymorphic: true

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
