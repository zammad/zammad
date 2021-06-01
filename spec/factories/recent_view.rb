# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory :recent_view do
    transient do
      o         { Ticket.first }
      user_role { :agent }
    end

    recent_view_object_id { ObjectLookup.by_name(o.class.name) }
    o_id { o.id }

    # assign to an existing user, if possible
    created_by_id do
      User.find { |u| u.role?(user_role.capitalize) }&.id ||
        create(user_role).id
    end
  end
end
