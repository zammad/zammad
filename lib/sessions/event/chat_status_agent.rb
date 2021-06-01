# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sessions::Event::ChatStatusAgent < Sessions::Event::ChatBase

=begin

a agent requests a the current state of all chat sessions

payload

  {
    event: 'chat_status_agent',
    data: {},
  }

return is sent as message back to peer

=end

  def run
    return super if super

    # check if user has permissions
    return if !permission_check('chat.agent', 'chat')

    # renew timestamps
    state = Chat::Agent.state(@session['id'])
    Chat::Agent.state(@session['id'], state)

    # update recipients of existing sessions
    Chat::Session.where(state: 'running', user_id: @session['id']).order(created_at: :asc).each do |chat_session|
      chat_session.add_recipient(@client_id, true)
    end
    {
      event: 'chat_status_agent',
      data:  Chat.agent_state_with_sessions(@session['id']),
    }
  end

end
