# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::TwoFactor
  class RecoveryInputType < Gql::Types::BaseInputObject
    description 'Payload for the two factor recovery authentication'

    argument :recovery_code, String, description: 'Two factor recovery code'
  end
end
