# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  # Shared by :from_users and :to_users so both survive when the traits are combined.
  user_preferences = lambda do
    { from: from_users, to: to_users }.compact_blank.transform_values do |users|
      users.map do |user|
        {
          caller_id: (Cti::Log.pluck(:call_id).map(&:to_i).max || 0).next,
          comment:   user.fullname,
          level:,
          object:    'User',
          o_id:      user.id,
          user_id:   user.id,
        }
      end
    end
  end

  factory :'cti/log', aliases: %i[cti_log] do
    direction { %w[in out].sample }
    state     { 'newCall' }
    from      { '4930609854180' }
    to        { '4930609811111' }
    call_id   { (Cti::Log.pluck(:call_id).map(&:to_i).max || 0).next } # has SQL UNIQUE constraint
    done      { false }

    transient do
      level      { 'known' }
      from_users { [] }
      to_users   { [] }
      waiting    { nil }
      duration   { nil }
    end

    duration_waiting_time { waiting }
    duration_talking_time { duration }

    trait :with_preferences do
      preferences { Cti::CallerId.get_comment_preferences(from, 'from')&.last }
    end

    trait :inbound do
      direction { 'in' }
    end

    trait :outbound do
      direction { 'out' }
    end

    trait :ringing do
      state { 'newCall' }
    end

    trait :connected do
      state { 'answer' }
    end

    trait :not_reached do
      state   { 'hangup' }
      comment { 'noAnswer' }
    end

    trait :busy do
      state   { 'hangup' }
      comment { 'busy' }
    end

    trait :not_found do
      state   { 'hangup' }
      comment { 'notFound' }
    end

    trait :handled do
      state   { 'hangup' }
      comment { 'normalClearing' }
    end

    trait :voicemail do
      state   { 'hangup' }
      comment { 'voicemail' }
    end

    trait :blocked do
      state   { 'hangup' }
      comment { 'blocked' }
    end

    trait :done do
      done { true }
    end

    trait :maybe do
      transient do
        level { 'maybe' }
      end
    end

    trait :with_from_users do
      transient do
        from_users { [create(:customer, :with_phone)] }
      end

      from { TelephoneNumber.parse(from_users[0]&.phone).original_number || '4930609854180' }

      preferences(&user_preferences)
    end

    trait :with_to_users do
      transient do
        to_users { [create(:customer, :with_phone)] }
      end

      to { TelephoneNumber.parse(to_users[0]&.phone).original_number || '4930609811111' }

      preferences(&user_preferences)
    end
  end
end
