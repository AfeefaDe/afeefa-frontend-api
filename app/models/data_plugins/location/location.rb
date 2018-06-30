module DataPlugins::Location
  class Location < ApplicationRecord
    self.table_name = 'addresses'

    def as_json(*args)
      {
        id: self.id,
        title: self.title || '',
        street: self.street || '',
        zip: self.zip || '',
        city: self.city || '',
        lat: self.lat || '',
        lon: self.lon || '',
        directions: self.directions || ''
      }
    end
  end
end
