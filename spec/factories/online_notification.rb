# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory :online_notification do
    transient do
      o { Ticket.first }
    end

    object_lookup_id { ObjectLookup.by_name(o.class.name) }
    o_id             { o.id }
    type_lookup_id   { TypeLookup.by_name('updated') }
    seen             { false }
    user_id          { 1 }
    created_by_id    { 1 }
    updated_by_id    { 1 }
    created_at       { Time.zone.now }
    updated_at       { Time.zone.now }
  end
end
