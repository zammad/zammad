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
            timeframes: [ ['00:00', '23:59'] ]
          },
          tue: {
            active:     true,
            timeframes: [ ['00:00', '23:59'] ]
          },
          wed: {
            active:     true,
            timeframes: [ ['00:00', '23:59'] ]
          },
          thu: {
            active:     true,
            timeframes: [ ['00:00', '23:59'] ]
          },
          fri: {
            active:     true,
            timeframes: [ ['00:00', '23:59'] ]
          },
          sat: {
            active:     true,
            timeframes: [ ['00:00', '23:59'] ]
          },
          sun: {
            active:     true,
            timeframes: [ ['00:00', '23:59'] ]
          },
        }
      end
    end
  end
end
