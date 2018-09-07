module Entry

  extend ActiveSupport::Concern

  included do
    belongs_to :category, optional: true
    belongs_to :sub_category, class_name: 'Category', optional: true

    belongs_to :linked_contact, class_name: DataPlugins::Contact::Contact, foreign_key: :contact_id
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
        :linked_contact,
        :parent_orga,
        :navigation_items,
        linked_contact: [:contact_persons, :location]
      ]
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

      contact = nil

      if contact_info_attributes.present?
        contact_create_params = {
          web: contact_info_attributes['web'],
          social_media: contact_info_attributes['social_media'],
          spoken_languages: contact_info_attributes['spoken_languages'],
          owner_id: model.id,
          owner_type: model.class.name
        }

        contact = DataPlugins::Contact::Contact.create(contact_create_params)

        if contact_info_attributes['contact_person'].present? ||
          contact_info_attributes['mail'].present? ||
          contact_info_attributes['phone'].present?

          contact_person = DataPlugins::Contact::ContactPerson.create({
            name: contact_info_attributes['contact_person'],
            mail: contact_info_attributes['mail'],
            phone: contact_info_attributes['phone'],
            contact_id: contact.id
          })
        end
      end

      if location_attributes.present?
        unless contact
          contact = DataPlugins::Contact::Contact.new(
            owner_id: model.id,
            owner_type: model.class.name
          )
        end

        location_create_params = location_attributes.merge(
          title: location_attributes.delete(:placename),
          contact_id: contact.id,
          owner_id: model.id,
          owner_type: model.class.name
        )

        location = DataPlugins::Location::Location.create!(location_create_params)
        contact.location = location
        contact.save
      end

      annotation_category = AnnotationCategory.external_entry
      Annotation.create(entry: model, annotation_category: annotation_category)

      {
        model: model,
        success:
          model_save_success &&
            (location_attributes.blank? || location.id) &&
            (contact_info_attributes.blank? || contact.id)
      }
    end
  end

  def as_json(*args)
    contact = self.linked_contact
    location = contact && contact.location
    parent_orga = self.parent_orga

    if location && contact
      location.openingHours = contact.opening_hours
    end

    if contact && contact.contact_persons.first
      self.social_media = contact.social_media
      self.web = contact.web
      self.spoken_languages = contact.spoken_languages

      contact_person = contact.contact_persons.first
      if contact_person
        self.phone = contact_person.phone
        self.mail = contact_person.mail
        self.contact_person = contact_person.name
      end
    end

    sub_navigation_item = navigation_items.where.not(parent_id: nil).first
    if sub_navigation_item
      navigation_item = sub_navigation_item.parent
    else
      navigation_item = navigation_items.first
    end
    {
      id: self.id,
      entryType: self.entry_type,

      navigationId: navigation_item ? navigation_item.id : nil,
      subNavigationId: sub_navigation_item ? sub_navigation_item.id : nil,

      category: self.category,
      subCategory: self.sub_category ? self.sub_category.title : '',

      certified: self.certified_sfr,
      entryId: self.legacy_entry_id,
      image: self.media_url,
      imageType: self.media_type,
      supportWanted: self.support_wanted,
      supportWantedDetail: self.support_wanted_detail,
      tags: self.tags || '',
      type: self.type,
      created_at: self.created_at,
      updated_at: self.updated_at,

      navigation_items: self.navigation_items.pluck(:id),

      # contact params
      facebook: self.social_media || '',
      web: self.web || '',
      spokenLanguages: self.spoken_languages || '',

      # contact person params
      speakerPublic: self.contact_person || '',
      mail: self.mail || '',
      phone: self.phone || '',

      location: location ? [location] : []
    }
  end
end
