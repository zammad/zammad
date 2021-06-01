# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory :'chat/agent' do
    active { true }
    created_by_id { 1 }
    updated_by_id { 1 }
  end
end
