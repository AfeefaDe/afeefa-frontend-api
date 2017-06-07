class Event < ApplicationRecord
  include Entry

  after_initialize do |entry|
    entry.type = 2
  end

  def as_json(*args)
    json = super

    json[:dateFrom] = self.date_start.try(:strftime, '%F')
    json[:timeFrom] = self.date_start.try(:strftime, '%H:%M')
    json[:has_time_start] = self.time_start
    json[:dateTo] = self.date_end.try(:strftime, '%F')
    json[:timeTo] = self.date_end.try(:strftime, '%H:%M')
    json[:has_time_end] = self.time_end

    json
  end

end
