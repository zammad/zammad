# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory :token, aliases: %i[token_api api_token] do
    user
    action { 'api' }
    persistent { true }
    preferences do

      permission_hash = permissions.each_with_object({}) do |permission, result|
        result[permission] = true
      end

      {
        permission: permission_hash
      }
    end

    transient do
      permissions { [] }
    end

    factory :token_password_reset, aliases: %i[password_reset_token] do
      action { 'PasswordReset' }
    end

    factory :token_ical, aliases: %i[ical_token] do
      action { 'iCal' }
      persistent { true }
    end
  end
end
