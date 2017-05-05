FactoryGirl.define do
  factory :tag do
    tag_object_id { Tag::Object.lookup_by_name_and_create('Ticket').id }
    tag_item_id { Tag::Item.lookup_by_name_and_create('blub').id }
    created_by_id 1
  end
end
