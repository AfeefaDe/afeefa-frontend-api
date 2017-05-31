class Event < ApplicationRecord
  include Entry

  after_initialize do |entry|
    entry.type = 2
  end

  def as_json(*args)
    e = super

    e[:date_start] = self.date_start
    e[:has_time_start] = self.time_start
    e[:date_end] = self.date_end
    e[:has_time_end] = self.time_end

    e
  end

end
