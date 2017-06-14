# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create!([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create!(name: 'Luke', movie: movies.first)

module Seeds

  def self.recreate_all
    Orga.without_root.delete_all

    # orgas
    if Orga.root_orga
      orga0 = Orga.root_orga
      orga0.title = Orga::ROOT_ORGA_TITLE
      orga0.save!(validate: false)
    else
      orga0 = Orga.new(title: Orga::ROOT_ORGA_TITLE)
      orga0.save!(validate: false)
    end

  end
end
