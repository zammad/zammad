FactoryBot.define do
  factory :history do
    association :history_type, factory: :'history/type'
    association :history_object, factory: :'history/object'
    o_id { history_object.name.constantize.pluck(:id).sample }
    created_by_id { 1 }
  end
end
