FactoryGirl.define do

  factory :orga, parent: :entry, class: Orga do
    title 'an orga'

    parent_orga { Orga.root_orga }
  end


end
