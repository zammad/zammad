# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::TwoFactor::RecoveryCodesGenerate < BaseMutation
    include Gql::Concerns::HandlesPasswordRevalidationToken

    description 'Regenerates new two factor recovery codes'

    field :recovery_codes, [String], description: 'One-time two-factor authentication codes'

    requires_permission 'user_preferences.two_factor_authentication'

    def resolve(token:)
      token_object = verify_token!(token)

      codes = Service::User::TwoFactor::GenerateRecoveryCodes
        .with_current_user(context.current_user)
        .execute(force: true)

      if !codes
        raise Exceptions::UnprocessableContent, __('Could not generate recovery codes')
      end

      token_object.destroy

      { recovery_codes: codes }
    end
  end
end
