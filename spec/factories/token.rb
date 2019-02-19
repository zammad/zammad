FactoryBot.define do
  factory :token, aliases: %i[token_api api_token] do
    user
    action { 'api' }
    persistent { true }

    factory :token_password_reset, aliases: %i[password_reset_token] do
      action { 'PasswordReset' }
    end

    factory :token_ical, aliases: %i[ical_token] do
      action { 'iCal' }
      persistent { true }
    end
  end
end
