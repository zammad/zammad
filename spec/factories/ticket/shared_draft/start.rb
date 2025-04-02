# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :ticket_shared_draft_start, class: 'Ticket::SharedDraftStart' do
    name { Faker::Name.unique.name }
    group
    content { { content: true } }
    updated_by_id { 1 }
    created_by_id { 1 }

    trait :with_inline_image do
      content do
        {
          body:  'text and <img src="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/2wBDAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/wAARCAADAAEDAREAAhEBAxEB/8QAFAABAAAAAAAAAAAAAAAAAAAACv/EABQQAQAAAAAAAAAAAAAAAAAAAAD/xAAUAQEAAAAAAAAAAAAAAAAAAAAF/8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAwDAQACEQMRAD8AbgQDv//Z">',
          title: '123',
        }
      end
    end
  end
end
