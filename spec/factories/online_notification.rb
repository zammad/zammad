# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :online_notification do
    transient do
      o         { Ticket.first }
      type_name { 'update' }
    end

    object_lookup_id { ObjectLookup.by_name(o.class.name) }
    o_id             { o.id }
    type_lookup_id   { TypeLookup.by_name(type_name) }
    seen             { false }
    user_id          { 1 }
    meta             { {} }

    created_by_id    { 1 }
    updated_by_id    { 1 }
    created_at       { Time.zone.now }
    updated_at       { Time.zone.now }

    trait :with_bulk_job do
      transient do
        o { create(:online_notification_standalone) } # rubocop:disable FactoryBot/FactoryAssociationWithStrategy
        type_name { 'bulk_job' }
      end
    end
  end
end
