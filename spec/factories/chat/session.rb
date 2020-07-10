FactoryBot.define do
  factory :'chat/session' do
    chat_id { Chat.pluck(:id).sample }
  end
end
