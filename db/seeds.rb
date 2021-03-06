# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create!([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create!(name: 'Luke', movie: movies.first)

module Seeds

  def self.recreate_all
    DataModules::FeNavigation::FeNavigation.delete_all
    DataModules::FeNavigation::FeNavigation.create(id: 1)
    DataModules::FeNavigation::FeNavigationItem.delete_all
    DataModules::FeNavigation::FeNavigationItem.create(id: 1, navigation: DataModules::FeNavigation::FeNavigation.first)

    Orga.delete_all

    AnnotationCategory.delete_all
    Annotation.delete_all

    Category.delete_all

    # areas
    Area.delete_all
    Area.create!(title: 'dresden', lat_min: '50.811596', lat_max: '51.381457', lon_min: '12.983771', lon_max: '14.116620')
    Area.create!(title: 'leipzig', lat_min: '51.169806', lat_max: '51.455225', lon_min: '12.174588', lon_max: '12.659360')
    Area.create!(title: 'bautzen', lat_min: '51.001001', lat_max: '51.593835', lon_min: '13.710340', lon_max: '14.650444')

    # orga types
    OrgaType.delete_all
    OrgaType.create!(name: 'Root')
    OrgaType.create!(name: 'Organization')
    OrgaType.create!(name: 'Project')
    OrgaType.create!(name: 'Location')
    OrgaType.create!(name: 'Network')

    # annotations
    AnnotationCategory.create!(title: 'Kurzbeschreibung fehlt', generated_by_system: true)

    AnnotationCategory.create!(title: 'Kontaktdaten', generated_by_system: false)
    AnnotationCategory.create!(title: 'Ort', generated_by_system: false)
    AnnotationCategory.create!(title: 'Beschreibung', generated_by_system: false)
    AnnotationCategory.create!(title: 'Bild', generated_by_system: false)
    AnnotationCategory.create!(title: 'Kategorie', generated_by_system: false)
    AnnotationCategory.create!(title: 'Zugehörigkeit', generated_by_system: false)

    AnnotationCategory.create!(title: 'Sonstiges', generated_by_system: false)

    AnnotationCategory.create!(title: 'ENTWURF', generated_by_system: false)
    AnnotationCategory.create!(title: 'DRINGEND', generated_by_system: false)
    AnnotationCategory.create!(title: 'EXTERNE EINTRAGUNG', generated_by_system: true)
    AnnotationCategory.create!(title: 'EXTERNE ANMERKUNG', generated_by_system: true)

      # TODO: Validierung einbauen und Migration handlen!
      # AnnotationCategory.create!(title: 'Unterkategorie passt nicht zur Hauptkategorie',
      #   generated_by_system: true)

  end
end
