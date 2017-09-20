class Orga < ApplicationRecord

  include Entry

  ROOT_ORGA_TITLE = 'ROOT-ORGA'

  belongs_to :parent_orga, class_name: 'Orga', foreign_key: 'parent_orga_id'

  scope :without_root, -> {
    where(title: nil).or(where.not(title: ROOT_ORGA_TITLE))
  }
  default_scope { without_root }

  # HOOKS
  before_validation :set_parent_orga_as_default, if: -> { parent_orga.blank? }

  after_initialize do |entry|
    entry.type = 0
    entry.entry_type = 'Orga'
  end

  # VALIDATIONS
  validates_uniqueness_of :title

  # CLASS METHODS
  class << self
    def is_root_orga?(orga_id)
      orga_id == root_orga.id
    end

    def root_orga
      @@root_orga ||= Orga.unscoped.find_by_title(ROOT_ORGA_TITLE)
    end
  end

  def as_json(*args)
    json = super

    json[:parentOrgaId] = Orga.is_root_orga?(self.parent_orga_id) ? nil : self.parent_orga_id

    json
  end

  private

  def set_parent_orga_as_default
    self.parent_orga = Orga.root_orga
  end

end
