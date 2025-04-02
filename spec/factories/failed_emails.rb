# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :failed_email do
    valid

    trait :valid do
      data { <<~MAIL.chomp }
        From: ME Bob <me@example.com>
        To: customer@example.com
        Subject: some subject

        Some Text
      MAIL
    end

    trait :invalid do
      data { 'not a mail' }
    end
  end
end
