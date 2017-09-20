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

    AnnotationCategory.delete_all
    Annotation.delete_all

    # orgas
    if Orga.root_orga
      orga0 = Orga.root_orga
      orga0.title = Orga::ROOT_ORGA_TITLE
      orga0.save!(validate: false)
    else
      orga0 = Orga.new(title: Orga::ROOT_ORGA_TITLE)
      orga0.save!(validate: false)
    end

    # annotations
    AnnotationCategory.create!(title: 'Titel ist zu lang', generated_by_system: true)
    AnnotationCategory.create!(title: 'Titel ist bereits vergeben', generated_by_system: true)
    AnnotationCategory.create!(title: 'Kurzbeschreibung ist zu lang', generated_by_system: true)
    AnnotationCategory.create!(title: 'Kurzbeschreibung fehlt', generated_by_system: true)
    AnnotationCategory.create!(title: 'Hauptkategorie fehlt', generated_by_system: true)
    AnnotationCategory.create!(title: 'Start-Datum fehlt', generated_by_system: true)

    AnnotationCategory.create!(title: 'Kontaktdaten', generated_by_system: false)
    AnnotationCategory.create!(title: 'Ort', generated_by_system: false)
    AnnotationCategory.create!(title: 'Beschreibung', generated_by_system: false)
    AnnotationCategory.create!(title: 'Bild', generated_by_system: false)
    AnnotationCategory.create!(title: 'Kategorie', generated_by_system: false)
    AnnotationCategory.create!(title: 'Zugehörigkeit', generated_by_system: false)

    AnnotationCategory.create!(title: 'Sonstiges', generated_by_system: false)

    AnnotationCategory.create!(title: 'ENTWURF', generated_by_system: false)
    AnnotationCategory.create!(title: 'DRINGEND', generated_by_system: false)

    # TODO: Validierung einbauen und Migration handlen!
    AnnotationCategory.create!(title: 'Unterkategorie passt nicht zur Hauptkategorie',
      generated_by_system: true)

  end
end
