# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::Locator
  class OrganizationInputType < BaseLocator
    description 'Locate an organization via id or internalId.'
    klass ::Organization
  end
end
