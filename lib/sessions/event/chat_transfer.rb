# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sessions::Event::ChatTransfer < Sessions::Event::ChatBase

  def run
    return super if super
    return if !permission_check('chat.agent', 'chat')

    # find chat session
    chat_session = Chat::Session.find_by(id: @payload['session_id'])
    if !chat_session
      return {
        event: 'chat_session_start',
        data:  {
          state:   'failed',
          message: 'No session available.',
        },
      }
    end
    chat_ids_to_notify = [chat_session.chat_id, @payload['chat_id']]
    chat_session.chat_id = @payload['chat_id']
    chat_session.state = 'waiting'
    chat_session.save

    # send state update with sessions to agents
    Chat.broadcast_agent_state_update(chat_ids_to_notify)

    # send transfer message to client
    message = {
      event: 'chat_session_notice',
      data:  {
        session_id: chat_session.session_id,
        message:    'Conversation transfered into other chat. Please stay tuned.',
      },
    }
    chat_session.send_to_recipients(message, @client_id)

    nil
  end

end
