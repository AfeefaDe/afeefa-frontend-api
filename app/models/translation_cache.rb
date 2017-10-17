class TranslationCache < ApplicationRecord

  belongs_to :cacheable, polymorphic: true

  scope :with_orgas, -> {
    joins("LEFT JOIN orgas \
      ON #{Orga.table_name}.id = #{TranslationCache.table_name}.cacheable_id \
      AND cacheable_type = '#{Orga.name}'")
  }

  scope :with_events, -> {
    joins("LEFT JOIN events \
      ON #{Event.table_name}.id = #{TranslationCache.table_name}.cacheable_id \
      AND cacheable_type = '#{Event.name}'")
  }

  scope :with_orgas_and_events, -> { with_orgas.with_events }

end
