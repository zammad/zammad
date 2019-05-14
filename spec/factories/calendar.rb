FactoryBot.define do
  factory :calendar do
    sequence(:name) { |n| "Escalation Test #{n}" }
    timezone        { 'Europe/Berlin' }
    default         { true }
    ical_url        { nil }

    business_hours do
      {
        mon: {
          active:     true,
          timeframes: [['09:00', '17:00']]
        },
        tue: {
          active:     true,
          timeframes: [['09:00', '17:00']]
        },
        wed: {
          active:     true,
          timeframes: [['09:00', '17:00']]
        },
        thu: {
          active:     true,
          timeframes: [['09:00', '17:00']]
        },
        fri: {
          active:     true,
          timeframes: [['09:00', '17:00']]
        },
        sat: {
          active:     false,
          timeframes: [['09:00', '17:00']]
        },
        sun: {
          active:     false,
          timeframes: [['09:00', '17:00']]
        }
      }
    end

    created_by_id { 1 }
    updated_by_id { 1 }

    trait :'24/7' do
      business_hours do
        {
          mon: {
            active:     true,
            timeframes: [ ['00:00', '24:00'] ]
          },
          tue: {
            active:     true,
            timeframes: [ ['00:00', '24:00'] ]
          },
          wed: {
            active:     true,
            timeframes: [ ['00:00', '24:00'] ]
          },
          thu: {
            active:     true,
            timeframes: [ ['00:00', '24:00'] ]
          },
          fri: {
            active:     true,
            timeframes: [ ['00:00', '24:00'] ]
          },
          sat: {
            active:     true,
            timeframes: [ ['00:00', '24:00'] ]
          },
          sun: {
            active:     true,
            timeframes: [ ['00:00', '24:00'] ]
          },
        }
      end
    end
  end
end
