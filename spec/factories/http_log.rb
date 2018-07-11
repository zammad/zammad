FactoryBot.define do
  factory :http_log do
    direction              'in'
    facility               'cti'
    add_attribute(:method) { 'post' }
    url                    'https://zammad.fqdn.com/api/v1/integration/cti/log'
    request                { { content: 'foo' } }
    response               { { content: 'bar' } }
    created_by_id          1
    updated_by_id          1
  end
end
