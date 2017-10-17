FactoryGirl.define do

  factory :translation, class: TranslationCache do
    cacheable nil
    title nil
    short_description nil
  end

end
