# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :'karma/activity_log', aliases: %i[karma_activity_log] do
    transient do
      o { Ticket.first }
    end

    o_id             { o.id }
    object_lookup_id { ObjectLookup.by_name(o.class.name) }
    user_id          { 1 }
    activity_id      { Karma::Activity.pluck(:id).sample }
    score            { 100 }
    score_total      { 100 }
  end
end
