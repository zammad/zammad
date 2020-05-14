FactoryBot.define do
  factory :user do
    transient do
      intro_clues { true }
    end

    login            { 'nicole.braun' }
    firstname        { 'Nicole' }
    lastname         { 'Braun' }
    sequence(:email) { |n| "nicole.braun#{n}@zammad.org" }
    password         { nil }
    active           { true }
    login_failed     { 0 }
    updated_by_id    { 1 }
    created_by_id    { 1 }

    callback(:after_stub, :before_create) do |object, context|
      next if !context.intro_clues

      object.preferences ||= {}
      object.preferences[:intro] = true
    end

    factory :customer_user, aliases: %i[customer] do
      role_ids { Role.signup_role_ids.sort }

      trait :with_org do
        organization
      end
    end

    factory :agent_user, aliases: %i[agent] do
      roles { Role.where(name: 'Agent') }
    end

    factory :admin_user, aliases: %i[admin] do
      roles { Role.where(name: %w[Admin Agent]) }
    end

    # make given password accessible for e.g. authentication logic
    before(:create) do |user|
      password_plain = user.password
      user.define_singleton_method(:password_plain, -> { password_plain })
    end
  end
end
