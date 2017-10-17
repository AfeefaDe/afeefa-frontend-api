FactoryGirl.define do

  factory :entry do
    short_description 'this is the short description'
    area 'dresden'
    state 'active'

    contact_infos { [build(:contact_info)] }
    locations { [build(:location)] }
    association :category, factory: :category

    after(:build) do |entry, evaluator|
      entry.contact_infos.each do |ci|
        ci.contactable = entry
      end
      entry.locations.each do |l|
        l.locatable = entry
      end
    end

    after(:create) do |entry, evaluator|
      evaluator.translated_locales.each do |locale|
        title = entry.title + "_#{locale}"
        short_description = entry.short_description + "_#{locale}"
        entry.translation_caches << build(:translation, cacheable: entry, language: locale, title: title, short_description: short_description)
      end
    end

    transient do
      translated_locales []
    end

  end


end
