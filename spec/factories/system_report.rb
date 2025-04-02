# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :system_report do
    data do
      {
        system_report: {
          'Version' => Version.get
        }
      }
    end
  end
end
