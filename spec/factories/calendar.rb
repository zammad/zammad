# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory :calendar do
    sequence(:name) { |n| "Escalation Test #{n}" }
    timezone        { 'Europe/Berlin' }
    default         { true }
    ical_url        { nil }
    created_by_id { 1 }
    updated_by_id { 1 }

    transient do
      public_holiday_date { nil }
    end

    public_holidays do
      next if public_holiday_date.blank?

      Array(public_holiday_date).each_with_object({}) do |elem, memo|
        memo[elem.to_s] = { active: true, summary: 'public holiday trait' }
      end
    end

    business_hours_9_17

    trait :business_hours_9_17 do
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
    end

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

    trait :'9-18/7' do
      business_hours_generated

      timeframe_alldays { ['09:00', '18:00'] }
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
