class Orga < ApplicationRecord
  include Entry

  ROOT_ORGA_TITLE = 'ROOT-ORGA'

  scope :without_root, -> {
    where(title: nil).or(where.not(title: ROOT_ORGA_TITLE))
  }
  default_scope { without_root }

  after_initialize do |orga|
    orga.type = 2
  end
end
