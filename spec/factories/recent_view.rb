FactoryBot.define do
  factory :recent_view do
    recent_view_object_id { ObjectLookup.by_name('User') }
    o_id 1
    created_by_id 1
    created_at Time.zone.now
    updated_at Time.zone.now
  end
end
