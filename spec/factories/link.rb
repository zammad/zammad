FactoryGirl.define do
  factory :link do
    link_type_id { Link::Type.find_by(name: 'normal').id }
    link_object_source_id { Link::Object.find_by(name: 'Ticket').id }
    link_object_target_id { Link::Object.find_by(name: 'Ticket').id }
  end
end
