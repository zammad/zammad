FactoryBot.define do
  factory :cti_caller_id, class: 'cti/caller_id' do
    caller_id '1234567890'
    level     :known
    object    :User
    o_id      { User.last.id }
    user_id   { User.last.id }
  end
end
