FactoryGirl.define do
  sequence :email do |n|
    "nicole.braun#{n}@zammad.org"
  end
end

FactoryGirl.define do

  factory :user do
    login         'nicole.braun'
    firstname     'Nicole'
    lastname      'Braun'
    email         { generate(:email) }
    password      'zammad'
    active        true
    login_failed  0
    updated_by_id 1
    created_by_id 1
  end

  factory :customer_user, parent: :user do
    role_ids { Role.signup_role_ids.sort }
  end

  factory :user_login_failed, parent: :user do
    login_failed { (Setting.get('password_max_login_failed').to_i || 10) + 1 }
  end
end
