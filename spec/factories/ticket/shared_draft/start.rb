# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :ticket_shared_draft_start, class: 'Ticket::SharedDraftStart' do
    name    { Faker::Name.unique.name }
    group   { create(:group) }
    content { { content: true } }
  end
end
