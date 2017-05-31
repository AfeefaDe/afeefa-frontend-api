module Entry

  extend ActiveSupport::Concern

  included do
    belongs_to :category, optional: true
    belongs_to :sub_category, class_name: 'Category', optional: true

    has_many :locations, as: :locatable
    has_many :contact_infos, as: :contactable
    has_many :translation_caches, as: :cacheable, dependent: :destroy, class_name: 'TranslationCache'

    attr_accessor :type, :phone, :mail, :social_media, :web, :contact_person, :spoken_languages
  end

  def as_json(*args)
    location = self.locations.first
    contact = self.contact_infos.first

    trans_title = nil
    trans_description = nil
    trans_short_description = nil

    if args[0][:language] != EntriesController::DEFAULT_LOCALE
      self.translation_caches.each do |t|
        if t.language == args[0][:language]
          trans_title = t[:title]
          trans_description = t[:description]
          trans_short_description = t[:short_description]
        end
      end
    end

    if location and contact
      location.openingHours = contact.opening_hours
    end

    if contact
      @phone = contact.phone
      @mail = contact.mail
      @facebook = contact.social_media
      @web = contact.web
      @contact_person = contact.contact_person
      @spoken_languages = contact.spoken_languages
    end

    {
        id: self.id,
        category: self.category,
        certified: self.certified_sfr,
        description: trans_description || self.description,
        descriptionShort: trans_short_description || self.short_description,
        entryId: self.legacy_entry_id,
        facebook: self.facebook || '',
        forChildren: self.for_children,
        image: self.media_url,
        imageType: self.media_type,
        location: self.locations,
        mail: self.mail || '',
        name: trans_title || self.title || '',
        phone: self.phone || '',
        speakerPublic: self.contact_person || '',
        spokenLanguages: self.spoken_languages || '',
        subCategory: self.sub_category ? self.sub_category.title : '',
        supportWanted: self.support_wanted,
        tags: '',
        type: self.type,
        web: self.web || '',
        created_at: self.created_at,
        updated_at: self.updated_at
    }
  end
end