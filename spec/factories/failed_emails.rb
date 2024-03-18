# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :failed_email do
    data { <<~MAIL.chomp }
      From: ME Bob <me@example.com>
      To: customer@example.com
      Subject: some subject

      Some Text
    MAIL
  end
end
