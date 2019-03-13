FactoryBot.define do
  factory :location do
    street { 'Hauptstr. 1' }

    factory :location_dresden do
      street { 'Bayrische Str.8' }
      zip { '01060' }
      city { 'Dresden' }
      country { 'Deutschland' }
    end
  end
end
