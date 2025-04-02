# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :activity_stream do
    transient do
      o { Ticket.first }
    end

    type factory: %i[type_lookup]
    activity_stream_object_id { ObjectLookup.by_name(o.class.name) }
    o_id                      { o.id }
    created_by_id             { 1 }
  end
end
