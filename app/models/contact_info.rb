class ContactInfo < ApplicationRecord
  belongs_to :orgas, foreign_key: 'contactable_id'
end
