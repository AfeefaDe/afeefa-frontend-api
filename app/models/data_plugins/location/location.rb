module DataPlugins::Location
  class Location < ApplicationRecord
    self.table_name = 'addresses'

    attr_accessor :openingHours

    def as_json(*args)
      {
        id: self.id,
        placename: self.title || '',
        street: self.street || '',
        zip: self.zip || '',
        city: self.city || '',
        lat: self.lat || '',
        lon: self.lon || '',
        openingHours: self.openingHours || '',
        arrival: self.directions || ''
      }
    end
  end
end
