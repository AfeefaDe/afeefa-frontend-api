class ContactInfo < ApplicationRecord
  belongs_to :contactable, polymorphic: true
end
