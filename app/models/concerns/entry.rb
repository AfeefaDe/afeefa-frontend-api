module Entry

  extend ActiveSupport::Concern

  included do
    belongs_to :category, optional: true
    belongs_to :sub_category, class_name: 'Category', optional: true

    has_many :locations, as: :locatable
    has_many :contact_infos, as: :contactable

    attr_accessor :type, :phone, :mail, :facebook, :web, :contact_person, :spoken_languages
  end

  def as_json(*args)
    l = self.locations.first
    c = self.contact_infos.first

    if l and c then
      l.openingHours = c.opening_hours
    end

    if c then
      @phone = c.phone
      @mail = c.mail
      @facebook = c.facebook
      @web = c.web
      @contact_person = c.contact_person
      @spoken_languages = c.spoken_languages
    end

    {
      :id => self.id,
      :category => self.category,
      :certified => self.certified_sfr,
      :description => self.description,
      :descriptionShort => 'Noch NIX',
      :legacyEntryId => self.legacy_entry_id,
      :facebook => self.facebook || '',
      :forChildren => self.for_children,
      :image => self.media_url,
      :imageType => self.media_type,
      :location => self.locations,
      :mail => self.mail || '',
      :name => self.title || '',
      :phone => self.phone || '',
      :speakerPublic => self.contact_person || '',
      :spokenLanguages => self.spoken_languages || '',
      :subCategory => self.sub_category ? self.sub_category.title : '',
      :supportWanted => self.support_wanted,
      :tags => '',
      :type => self.type,
      :web => self.web || '',
      :created_at => self.created_at,
      :updated_at => self.updated_at
    }
  end

end
