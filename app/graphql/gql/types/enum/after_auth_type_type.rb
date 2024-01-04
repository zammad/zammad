# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class AfterAuthTypeType < BaseEnum
    description 'Possible AfterAuth message types'

    Auth::AfterAuth.backends.each do |klass|
      value klass.type, klass.type
    end
  end
end
