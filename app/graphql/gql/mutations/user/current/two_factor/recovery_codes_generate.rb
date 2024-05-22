# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::TwoFactor::RecoveryCodesGenerate < BaseMutation
    description 'Regenerates new two factor recovery codes'

    field :recovery_codes, [String], description: 'One-time two-factor authentication codes'

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?('user_preferences.two_factor_authentication')
    end

    def resolve
      codes = Service::User::TwoFactor::GenerateRecoveryCodes
        .new(user: context.current_user, force: true)
        .execute

      if !codes
        raise Exceptions::UnprocessableEntity, __('Could not generate recovery codes')
      end

      { recovery_codes: codes }
    end
  end
end
