module Entry

  extend ActiveSupport::Concern

  included do
    belongs_to :category, optional: true
    belongs_to :sub_category, class_name: 'Category', optional: true

    belongs_to :parent_orga, class_name: 'Orga', foreign_key: 'parent_orga_id'

    has_many :locations, as: :locatable
    has_many :contact_infos, as: :contactable
    has_many :translation_caches, as: :cacheable, dependent: :destroy, class_name: 'TranslationCache'

    attr_accessor :type, :entryType, :phone, :mail, :social_media, :web, :contact_person, :spoken_languages
  end

  def as_json(*args)
    location = self.locations.first
    contact = self.contact_infos.first
    parent_orga = self.parent_orga

    trans_title, trans_description, trans_short_description = nil

    if args[0][:language] != EntriesController::DEFAULT_LOCALE
      self.translation_caches.each do |t|
        if t.language == args[0][:language]
          trans_title = t[:title]
          trans_description = t[:description]
          trans_short_description = t[:short_description]
          break
        end
      end
    end

    if location and contact
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
        if self.inheritance and self.inheritance.include?('short_description')
          if (parent_attribute = parent_orga.send(attribute))
            pp parent_attribute
            pp self.send(attribute)
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
        end
      end

    end

    {
      id: self.id,
      entryType: self.entryType,
      category: self.category,
      certified: self.certified_sfr,
      description: trans_description || self.description,
      descriptionShort: trans_short_description || self.short_description,
      entryId: self.legacy_entry_id,
      facebook: self.social_media || '',
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
      inheritance: inheritance,
      created_at: self.created_at,
      updated_at: self.updated_at
    }
  end
end
