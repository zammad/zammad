# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory :'chat/message' do
    chat_session { create(:'chat/session') }
    content { 'test 1234' }
    created_by_id { 1 }
  end
end
