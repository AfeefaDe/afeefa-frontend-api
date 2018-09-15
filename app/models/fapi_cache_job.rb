class FapiCacheJob < ApplicationRecord

  belongs_to :entry, polymorphic: true, optional: true
  belongs_to :area, optional: true

  scope :not_started, -> { where(started_at: nil) }

  scope :running, -> { where.not(started_at: nil).where(finished_at: nil) }

  scope :finished, -> { where.not(finished_at: nil) }

end
