class Event < ApplicationRecord
  include Entry

  after_initialize do |entry|
    entry.type = 2
  end

  scope :upcoming, -> {
    now = Time.now.beginning_of_day
    # date_start >= today 00:00
    # date_end >= today 00:00
    where('date_start >= ?', now).
    or(where('date_end >= ?', now))
  }
  default_scope { upcoming }

  def as_json(*args)
    json = super

    json[:hostOrgaId] = Orga.is_root_orga?(self.orga_id) ? nil : self.orga_id

    date_start = self.date_start.try(:in_time_zone, 'Berlin')
    date_end = self.date_end.try(:in_time_zone, 'Berlin')

    json[:dateFrom] = date_start.try(:strftime, '%F')
    json[:timeFrom] = date_start.try(:strftime, '%H:%M')
    json[:has_time_start] = self.time_start

    json[:dateTo] = date_end.try(:strftime, '%F')
    json[:timeTo] = date_end.try(:strftime, '%H:%M')
    json[:has_time_end] = self.time_end

    json
  end

end
