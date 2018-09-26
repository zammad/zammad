FactoryBot.define do
  factory :external_credential do
    credentials { { 'application_id' => '1234', 'application_secret' => 'secret' } }
  end
end
