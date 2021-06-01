# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory :'chat/session' do
    chat_id { Chat.pluck(:id).sample }
  end
end
