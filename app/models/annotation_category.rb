class AnnotationCategory < ApplicationRecord

  has_many :annotations
  has_many :events, through: :annotations, source: :entry, source_type: 'Event'
  has_many :orgas, through: :annotations, source: :entry, source_type: 'Orga'

  # CLASS METHODS
  class << self
    def attribute_whitelist_for_json
      default_attributes_for_json
    end

    def default_attributes_for_json
      %i(title generated_by_system).freeze
    end

    def external_entry
      @@external_entry ||= AnnotationCategory.where(title: 'EXTERNE EINTRAGUNG').last.freeze
      raise 'annotation category for external_entry not found' unless @@external_entry
      @@external_entry
    end

    def external_feedback
      @@external_feedback ||= AnnotationCategory.where(title: 'EXTERNE ANMERKUNG').last.freeze
      raise 'annotation category for external_feedback not found' unless @@external_feedback
      @@external_feedback
    end
  end

end
