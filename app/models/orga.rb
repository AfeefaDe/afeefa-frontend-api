class Orga < ApplicationRecord
  include Entry

  ROOT_ORGA_TITLE = 'ROOT-ORGA'

  scope :without_root, -> {
    where(title: nil).or(where.not(title: ROOT_ORGA_TITLE))
  }
  default_scope { without_root }

  after_initialize do |entry|
    entry.type = 0
    entry.entryType = 'orga'
  end

  # CLASS METHODS
  class << self
    @@root_orga = Orga.unscoped.find_by_title(ROOT_ORGA_TITLE)

    def is_root_orga?(orga_id)
      orga_id == @@root_orga.id
    end
  end

  def as_json(*args)
    json = super

    json[:parentOrgaId] = Orga.is_root_orga?(self.parent_orga_id) ? nil : self.parent_orga_id

    json
  end

end
