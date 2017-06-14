class TranslationCache < ApplicationRecord

  belongs_to :cacheable, polymorphic: true
  attr_accessor :title, :description, :short_description

end
