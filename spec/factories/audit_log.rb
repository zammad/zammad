# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :audit_log do
    action_type { 'update' }
    auditable   { association :user }
    value_from  { { 'firstname' => 'Nicole' } }
    value_to    { { 'firstname' => 'Nicki' } }
    source_ip   { '127.0.0.1' }
  end
end
