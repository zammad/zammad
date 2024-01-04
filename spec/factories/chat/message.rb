# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :'chat/message' do
    chat_session factory: :'chat/session'
    content { 'test 1234' }
    created_by_id { 1 }
  end
end
