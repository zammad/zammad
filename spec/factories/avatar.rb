# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory :avatar do
    object_lookup_id { ObjectLookup.by_name('User') }
    o_id             { 1 }
    default          { true }
    deletable        { true }
    initial          { false }
    source           { 'init' }
    source_url       { nil }
    created_by_id    { 1 }
    updated_by_id    { 1 }
    created_at       { Time.zone.now }
    updated_at       { Time.zone.now }
  end
end
