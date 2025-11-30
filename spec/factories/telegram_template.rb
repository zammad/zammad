# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :telegram_template do
    sequence(:name) { |n| "Telegram Template #{n}" }
    content { 'Hello {{customer.firstname}}, your ticket #{{ticket.number}} is being processed.' }
    note { 'Sample telegram template' }
    active { true }
    parse_mode { 'Markdown' }
    keyboard_buttons { [] }
    created_by_id { 1 }
    updated_by_id { 1 }
  end
end
