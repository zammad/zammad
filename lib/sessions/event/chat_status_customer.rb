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

    # check if it's a chat sessin reconnect
    session_id = nil
    if @data['data']['session_id']
      session_id = @data['data']['session_id']
    end
    {
      event: 'chat_status_customer',
      data: chat.customer_state(session_id),
    }
  end
end
