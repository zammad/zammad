# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory :history do
    transient do
      o { Ticket.first }

      history_type { 'update' }
      history_attribute { 'state' }
    end

    o_id          { o.id }
    created_by_id { 1 }

    history_type_id do
      History.type_lookup(history_type).id
    end

    history_attribute_id do
      History.attribute_lookup(history_attribute).id
    end

    history_object_id do
      History.object_lookup(o.class.name).id
    end
  end
end
