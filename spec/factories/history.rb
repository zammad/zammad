FactoryBot.define do
  factory :history do
    transient do
      o { Ticket.first }
    end

    association :history_type, factory: :'history/type'
    o_id          { o.id }
    created_by_id { 1 }

    history_object_id do
      History::Object.lookup(name: o.class.name)&.id || create(:'history/object', name: o.class.name).id
    end
  end
end
