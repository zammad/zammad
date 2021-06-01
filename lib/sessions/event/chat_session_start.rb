# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sessions::Event::ChatSessionStart < Sessions::Event::ChatBase

=begin

a agent start`s a new chat session

payload

  {
    event: 'chat_session_start',
    data: {},
  }

return is sent as message back to peer

=end

  def run
    return super if super
    return if !permission_check('chat.agent', 'chat')

    # find first in waiting list
    chat_user = User.lookup(id: @session['id'])
    chat_ids = Chat.agent_active_chat_ids(chat_user)
    chat_session = if @payload['chat_id']
                     Chat::Session.where(state: 'waiting', chat_id: @payload['chat_id']).order(created_at: :asc).first
                   else
                     Chat::Session.where(state: 'waiting', chat_id: chat_ids).order(created_at: :asc).first
                   end
    if !chat_session
      return {
        event: 'chat_session_start',
        data:  {
          state:   'failed',
          message: 'No session available.',
        },
      }
    end
    chat_session.user_id = chat_user.id
    chat_session.state = 'running'
    chat_session.preferences[:participants] = chat_session.add_recipient(@client_id)
    chat_session.save

    session_attributes = chat_session.attributes
    session_attributes['messages'] = []
    Chat::Message.where(chat_session_id: chat_session.id).order(created_at: :asc).each do |message|
      session_attributes['messages'].push message.attributes
    end

    # send chat_session_init to customer client
    if session_attributes['messages'].blank?
      user = chat_session.agent_user
      data = {
        event: 'chat_session_start',
        data:  {
          state:      'ok',
          agent:      user,
          session_id: chat_session.session_id,
          chat_id:    chat_session.chat_id,
        },
      }
      chat_session.send_to_recipients(data, @client_id)
    end

    # send to agent
    data = {
      event: 'chat_session_start',
      data:  {
        session: session_attributes,
      },
    }
    Sessions.send(@client_id, data)

    # send state update with sessions to agents
    Chat.broadcast_agent_state_update([chat_session.chat_id])

    # send position update to other waiting sessions
    Chat.broadcast_customer_state_update(chat_session.chat_id)

    nil
  end

end
