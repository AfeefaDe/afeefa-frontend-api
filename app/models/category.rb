class Category < ApplicationRecord

  has_many :orgas

  def as_json(*args)
    {
      id: self.id,
      name: self.title
    }
  end
end
