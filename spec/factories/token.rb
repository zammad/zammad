FactoryBot.define do
  factory :token do
    user
  end

  factory :token_password_reset, parent: :token do
    action 'PasswordReset'
  end
end
