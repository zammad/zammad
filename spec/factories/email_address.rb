FactoryBot.define do
  factory :email_address do
    email         'zammad@localhost'
    realname      'zammad'
    channel_id    1
    created_by_id 1
    updated_by_id 1
  end
end
