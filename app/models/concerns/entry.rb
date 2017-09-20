module Entry

  extend ActiveSupport::Concern

  included do
    belongs_to :category, optional: true
    belongs_to :sub_category, class_name: 'Category', optional: true

    # belongs_to :parent_orga, class_name: 'Orga', foreign_key: :orga_id

    has_many :locations, as: :locatable
    has_many :contact_infos, as: :contactable
    has_many :translation_caches, as: :cacheable, dependent: :destroy, class_name: 'TranslationCache'

    attr_accessor :type, :entry_type, :phone, :mail, :social_media, :web, :contact_person, :spoken_languages
  end

  def as_json(*args)
    location = self.locations.first
    contact = self.contact_infos.first
    parent_orga = self.parent_orga

    trans_title, trans_description, trans_short_description = nil

    locale = args[0][:language]
    if locale != TranslationCacheMetaDatum::DEFAULT_LOCALE
      if translation_caches.any?
        translation_caches.each do |translation_cache|
          if translation_cache.language == args[0][:language]
            trans_title = translation_cache[:title]
            trans_description = translation_cache[:description]
            trans_short_description = translation_cache[:short_description]
            break
          end
        end
      else
        Rails.logger.warn "no translations found for locale #{locale}"
      end
    end

    if location && contact
      location.openingHours = contact.opening_hours
    end

    inheritance = self.inheritance || ''
    inheritance = {
      short_description: inheritance.include?('short_description'),
      contact_infos: inheritance.include?('contact_infos'),
      locations: inheritance.include?('locations')
    }

    if contact
      self.phone = contact.phone
      self.mail = contact.mail
      self.social_media = contact.social_media
      self.web = contact.web
      self.contact_person = contact.contact_person
      self.spoken_languages = contact.spoken_languages
    end

    if parent_orga
      [:short_description].each do |attribute|
        if self.inheritance && self.inheritance.include?('short_description')
          if (parent_attribute = parent_orga.send(attribute))
            self.send("#{attribute}=",
              [parent_attribute, self.send(attribute)].join("\n\n"))
          end
        end
      end

      [:description].each do |attribute|
        if send(attribute).blank?
          if (parent_attribute = parent_orga.send(attribute))
            self.send("#{attribute}=", parent_attribute)
          end
        end
      end

      if parent_orga.contact_infos.first
        if contact
          [:mail, :phone, :contact_person, :web, :social_media, :spoken_languages].each do |attribute|
            if send(attribute).blank?
              if (parent_attribute = parent_orga.contact_infos.first.send(attribute))
                self.send("#{attribute}=", parent_attribute)
              end
            end
          end
        else
          contact = parent_orga.contact_infos.first
          self.phone = contact.phone
          self.mail = contact.mail
          self.social_media = contact.social_media
          self.web = contact.web
          self.contact_person = contact.contact_person
          self.spoken_languages = contact.spoken_languages
        end
      end

    end

    {
      id: self.id,
      entryType: self.entry_type,
      category: self.category,
      certified: self.certified_sfr,
      description: trans_description || self.description,
      descriptionShort: trans_short_description || self.short_description,
      entryId: self.legacy_entry_id,
      facebook: self.social_media || '',
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
      supportWantedDetail: self.support_wanted_detail,
      tags: self.tags || '',
      type: self.type,
      web: self.web || '',
      inheritance: inheritance,
      created_at: self.created_at,
      updated_at: self.updated_at
    }
  end
end
