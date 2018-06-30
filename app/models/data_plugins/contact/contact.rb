module DataPlugins::Contact
  class Contact < ApplicationRecord
    # disable rails single table inheritance
    self.inheritance_column = :_type_disabled

    has_many :contact_persons, class_name: DataPlugins::Contact::ContactPerson
    belongs_to :location, class_name: DataPlugins::Location::Location, optional: true

    def as_json(*args)
      {
        id: self.id,
        title: self.title || '',
        web: self.web || '',
        social_media: self.social_media || '',
        spoken_languages: self.spoken_languages || '',
        opening_hours: self.opening_hours || '',
        location: self.location,
        contact_persons: self.contact_persons
      }
    end
  end
end
