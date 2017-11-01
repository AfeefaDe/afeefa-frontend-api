class Category < ApplicationRecord

  has_many :orgas
  has_many :sub_categories, class_name: 'Category', foreign_key: 'parent_id'

  def as_json(*args)
    {
      id: self.id,
      name: self.title,
      sub: sub_categories.map { |x| x.as_json(args) }
    }
  end
end
