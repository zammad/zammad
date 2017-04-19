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

  factory :user_login_failed, parent: :user do
    login_failed { (Setting.get('password_max_login_failed').to_i || 10) + 1 }
  end

  factory :user_legacy_password_sha2, parent: :user do
    after(:build) { |user| user.class.skip_callback(:validation, :before, :ensure_password, if: -> { password && password.start_with?('{sha2}') }) }
    password '{sha2}dd9c764fa7ea18cd992c8600006d3dc3ac983d1ba22e9ba2d71f6207456be0ba' # zammad
  end
end
