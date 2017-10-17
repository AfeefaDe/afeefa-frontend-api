FactoryGirl.define do

  factory :event, parent: :entry, class: Event do
    title 'an event'
    date_start { Date.tomorrow }

    parent_orga { build(:orga, title: "orga for #{title}", area: area) }
  end

end
