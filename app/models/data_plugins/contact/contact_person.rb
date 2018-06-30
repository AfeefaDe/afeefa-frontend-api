module DataPlugins::Contact
  class ContactPerson < ApplicationRecord
    self.table_name = 'contact_persons'

    def as_json(*args)
      {
        id: self.id,
        name: self.name || '',
        role: self.role || '',
        mail: self.mail || '',
        phone: self.phone || ''
      }
    end
  end
end
