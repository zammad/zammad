# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory :link do
    transient do
      link_type { 'normal' }
      link_object_source { from.class.name }
      link_object_target { to.class.name }
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
