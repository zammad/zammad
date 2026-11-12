# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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

    # claim first in waiting list
    chat_user = User.lookup(id: @session['id'])
    chat_ids = @payload['chat_id'] ? [@payload['chat_id']] : Chat.agent_active_chat_ids(chat_user)
    chat_session = Chat::Session.claim_next(chat_ids, chat_user)
    if !chat_session
      return {
        event: 'chat_session_start',
        data:  {
          state:   'failed',
          message: __('No session available.'),
        },
      }
    end
    # The claim runs no callbacks: the save of a new recipient tells the search index, but the client of
    #   an agent who accepts again what they transferred takes part already, and nothing is saved for it.
    if chat_session.preferences[:participants]&.include?(@client_id)
      chat_session.search_index_update_after_claim
    else
      chat_session.add_recipient(@client_id, true)
    end

    session_attributes = chat_session.attributes
    session_attributes['messages'] = []
    Chat::Message.where(chat_session_id: chat_session.id).reorder(created_at: :asc).each do |message|
      session_attributes['messages'].push message.attributes
    end

    # send chat_session_init to customer client
    chat_session.send_start_to_customer(@client_id)

    # send to agent
    data = {
      event: 'chat_session_start',
      data:  {
        session: session_attributes,
      },
    }
    Sessions.send(@client_id, data)

    # send state update with sessions to agents
    Chat.broadcast_agent_state_update([chat_session.chat_id], agent_ids: [chat_session.user_id])

    # send position update to other waiting sessions
    Chat.broadcast_customer_state_update(chat_session.chat_id)

    nil
  end

end
