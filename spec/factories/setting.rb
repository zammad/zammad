FactoryBot.define do
  factory :setting do
    title       { 'ABC API Token' }
    name        { 'abc_api_token' }
    area        { 'Integration::ABC' }
    description { 'API Token for ABC to access ABC.' }
    frontend    { false }
  end
end
