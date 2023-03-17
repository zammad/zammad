# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::Locator
  class UserInputType < BaseLocator
    description 'Locate a User via id or internalId.'
    klass ::User
  end
end
