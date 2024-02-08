# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::User
  class GroupPermissionEntryType < Gql::Types::BaseInputObject
    description 'Represents a User <-> Group permission entry.'

    argument :group_internal_id, Integer, description: 'Internal ID of the group'
    argument :access_type, [Gql::Types::Enum::PermissionAccessType], description: 'Assigned access levels for the user in the group'
  end
end
