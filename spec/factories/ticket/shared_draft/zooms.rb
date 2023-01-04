# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :ticket_shared_draft_zoom, class: 'Ticket::SharedDraftZoom' do
    ticket            { create(:ticket) }
    new_article       { { new_article: true } }
    ticket_attributes { { ticket_attributes: true } }
    updated_by_id { 1 }
    created_by_id { 1 }
  end
end
