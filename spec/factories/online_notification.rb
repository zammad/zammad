FactoryGirl.define do
  factory :online_notification do
    object_lookup_id { ObjectLookup.by_name('Ticket') }
    type_lookup_id { TypeLookup.by_name('Assigned to you') }
    seen false
    user_id 1
    created_by_id 1
    updated_by_id 1
    created_at Time.zone.now
    updated_at Time.zone.now
  end
end
