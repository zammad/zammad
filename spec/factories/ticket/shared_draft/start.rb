# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :ticket_shared_draft_start, class: 'Ticket::SharedDraftStart' do
    name    { Faker::Name.unique.name }
    group   { create(:group) }
    content { { content: true } }
    updated_by_id { 1 }
    created_by_id { 1 }
  end
end
