FactoryBot.define do
  factory :link do
    transient do
      link_type { 'normal' }
      link_object_source { 'Ticket' }
      link_object_target { 'Ticket' }
      from { Ticket.first }
      to   { Ticket.last }
    end

    link_type_id             { Link::Type.create_if_not_exists(name: link_type, active: true).id }
    link_object_source_id    { Link::Object.create_if_not_exists(name: link_object_source).id }
    link_object_target_id    { Link::Object.create_if_not_exists(name: link_object_target).id }
    link_object_source_value { from.id }
    link_object_target_value { to.id }
  end
end
