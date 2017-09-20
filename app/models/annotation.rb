class Annotation < ApplicationRecord

  belongs_to :annotation_category
  belongs_to :entry, polymorphic: true

  #scope :with_annotation_category, -> {joins(:annotation_category)}

  scope :with_entries,
    -> {
      joins("LEFT JOIN orgas ON orgas.id = #{table_name}.entry_id AND entry_type = 'Orga'").
        joins("LEFT JOIN events ON events.id = #{table_name}.entry_id AND entry_type = 'Event'")
    }

  scope :grouped_by_entries, -> { group(:entry_id, :entry_type) }

  scope :by_area,
    ->(area) {
      where(
        'orgas.area = ? AND events.area IS NULL OR orgas.area IS NULL AND events.area = ?',
        area, area)
    }

end
