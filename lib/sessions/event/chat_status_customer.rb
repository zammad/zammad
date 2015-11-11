class Sessions::Event::ChatStatusCustomer < Sessions::Event::ChatBase

  def run

    chat_id = 1
    chat = Chat.find_by(id: chat_id)
    if !chat
      return {
        event: 'chat_status_customer',
        data: {
          state: 'no_such_chat',
        },
      }
    end

    {
      event: 'chat_status_customer',
      data: chat.state,
    }
  end
end
