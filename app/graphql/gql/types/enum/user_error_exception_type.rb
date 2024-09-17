# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class UserErrorExceptionType < BaseEnum
    description 'All user error exception values'

    # TODO: Move all supported exceptions to a separate namespace once there is a need for this mechanism globally.
    build_class_list_enum Service::Ticket::Update::Validator.exceptions.sort_by(&:name)
  end
end
