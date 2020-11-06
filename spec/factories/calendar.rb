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

    trait '23:59/7' do
      business_hours_generated

      timeframe_alldays { ['00:00', '23:59'] }
    end

    trait :business_hours_generated do
      transient do
        timeframe_alldays  { nil }
        timeframe_workdays { timeframe_alldays }
        timeframe_weekends { timeframe_alldays }
        config_workdays    { timeframe_workdays ? { active: true, timeframes: [timeframe_workdays] } : {} }
        config_weekends    { timeframe_weekends ? { active: true, timeframes: [timeframe_weekends] } : {} }
      end

      business_hours do
        hash = {}
        %i[mon tue wed thu fri].each_with_object(hash) { |elem, memo| memo[elem] = config_workdays }
        %i[sat sun].each_with_object(hash)             { |elem, memo| memo[elem] = config_weekends }
        hash
      end
    end
  end
end
