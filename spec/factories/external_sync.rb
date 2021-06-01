# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory :external_sync do
    source    { 'Some3rdPartyService' }
    source_id { SecureRandom.uuid }
    object    { 'Ticket' }
    o_id      { 1 }

    # https://github.com/thoughtbot/factory_bot/issues/1142
    after :build do |record, options|
      record.source_id = options.source_id
      record.source    = options.source
    end
  end
end
