module Entry

  extend ActiveSupport::Concern

  included do
    belongs_to :category, optional: true
    belongs_to :sub_category, class_name: 'Category', optional: true

    has_many :locations, as: :locatable
    has_many :contact_infos, as: :contactable
    has_many :contacts, class_name: DataPlugins::Contact::Contact, as: :owner
    has_many :translation_caches, as: :cacheable, class_name: 'TranslationCache'

    has_many :navigation_item_owners,
      class_name: DataModules::FeNavigation::FeNavigationItemOwner, as: :owner
    has_many :navigation_items, through: :navigation_item_owners

    attr_accessor :type, :entry_type, :phone, :mail, :social_media, :web, :contact_person, :spoken_languages

    def create_feedback(feedback_params:)
      annotation_category = AnnotationCategory.external_feedback
      annotation =
        Annotation.create(
          entry: self,
          annotation_category: annotation_category,
          detail: generate_feedback_message(feedback_params: feedback_params))

      annotation_success = annotation && annotation.persisted?
      unless annotation_success
        Rails.logger.warn(
          "feedback for entry [#{self.class}, #{self.id}] could not create annotation: " +
            "#{annotation.inspect}, errors: #{annotation.errors.messages.inspect}")
      end
      annotation_success
    end

    private

    def generate_feedback_message(feedback_params:)
      "#{feedback_params[:message]}\n#{feedback_params[:author]} " +
        "(#{[feedback_params[:mail], feedback_params[:phone]].join(', ')})"
    end
  end

  module ClassMethods
    def default_includes
      [
        :category,
        :sub_category,
        :contacts,
        :parent_orga,
        :navigation_items,
        contacts: [:contact_persons, :location],
        parent_orga: :contact_infos]
    end

    def create_via_frontend(model_atrtibtues:, contact_info_attributes: nil, location_attributes: nil)
      model = new(model_atrtibtues)
      model.parent_orga = Orga.root_orga
      model.state = :inactive

      unless model.valid?
        tries = 1
        while model.errors[:title].any? && (messages = model.errors[:title].join("\n")) &&
          messages.include?('bereits vergeben') && (tries += 1) <= 10
          model.title << "_#{Time.current.to_i}"
          model.valid?
        end
      end

      model_save_success = model.save
      if location_attributes.present?
        location = Location.new(location_attributes.merge(locatable: model))
      end
      if contact_info_attributes.present?
        contact_info = ContactInfo.new(contact_info_attributes.merge(contactable: model))
      end

      annotation_category = AnnotationCategory.external_entry
      Annotation.create(entry: model, annotation_category: annotation_category)

      {
        model: model,
        success:
          model_save_success &&
            (location_attributes.blank? || location.save) &&
            (contact_info_attributes.blank? || contact_info.save)
      }
    end
  end

  def as_json(*args)
    parent_orga = self.parent_orga

    # trans_title, trans_description, trans_short_description = nil

    # locale = args[0][:language]
    # if locale != Translation::DEFAULT_LOCALE
    #   translation = translation_caches.find_by(language: locale)
    #   if translation
    #     trans_title = translation[:title]
    #     trans_description = translation[:description]
    #     trans_short_description = translation[:short_description]
    #   else
    #     Rails.logger.warn "no translations found for #{entry_type} #{id} locale #{locale}"
    #   end
    # end

    # if parent_orga
    #   [:short_description].each do |attribute|
    #     if self.inheritance && self.inheritance.include?('short_description')
    #       if (parent_attribute = parent_orga.send(attribute))
    #         self.send("#{attribute}=",
    #           [parent_attribute, self.send(attribute)].join("\n\n"))
    #       end
    #     end
    #   end

    #   [:description].each do |attribute|
    #     if send(attribute).blank?
    #       if (parent_attribute = parent_orga.send(attribute))
    #         self.send("#{attribute}=", parent_attribute)
    #       end
    #     end
    #   end

    #   if parent_orga.contact_infos.first
    #     if contact
    #       [:mail, :phone, :contact_person, :web, :social_media, :spoken_languages].each do |attribute|
    #         if send(attribute).blank?
    #           if (parent_attribute = parent_orga.contact_infos.first.send(attribute))
    #             self.send("#{attribute}=", parent_attribute)
    #           end
    #         end
    #       end
    #     else
    #       contact = parent_orga.contact_infos.first
    #       self.phone = contact.phone
    #       self.mail = contact.mail
    #       self.social_media = contact.social_media
    #       self.web = contact.web
    #       self.contact_person = contact.contact_person
    #       self.spoken_languages = contact.spoken_languages
    #     end
    #   end

    # end

    {
      id: self.id,
      entryType: self.entry_type,
      category: self.category ? self.category.title : '',
      subCategory: self.sub_category ? self.sub_category.title : '',
      certified: self.certified_sfr,
      # description: trans_description || self.description,
      # descriptionShort: trans_short_description || self.short_description,
      entryId: self.legacy_entry_id,
      image: self.media_url,
      imageType: self.media_type,
      # name: trans_title || self.title || '',
      supportWanted: self.support_wanted,
      supportWantedDetail: self.support_wanted_detail,
      tags: self.tags || '',
      type: self.type,
      created_at: self.created_at,
      updated_at: self.updated_at,
      contact: self.contacts.first,
      navigation_items: self.navigation_items.pluck(:id)
    }
  end
end
