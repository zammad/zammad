# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sessions::Event::ChatBase < Sessions::Event::Base
  database_connection_required

  def run

    # check if feature is enabled
    return if Setting.get('chat')

    {
      event: 'chat_error',
      data:  {
        state: 'chat_disabled',
      },
    }
  end

  def current_chat_session
    Chat::Session.find_by(session_id: @payload['data']['session_id'])
  end

  def check_chat_session_exists
    if !@payload['data'] || !@payload['data']['session_id']
      error = {
        event: 'chat_error',
        data:  {
          state: 'Need session_id.',
        },
      }
      Sessions.send(@client_id, error)
      return
    end
    return true if current_chat_session

    error = {
      event: 'chat_error',
      data:  {
        state: "No such session id #{@payload['data']['session_id']}",
      },
    }
    Sessions.send(@client_id, error)
    false
  end

  def current_chat
    Chat.find_by(id: @payload['data']['chat_id'])
  end

  def check_chat_exists
    chat = current_chat
    return true if chat

    error = {
      event: 'chat_error',
      data:  {
        state: 'no_such_chat',
      },
    }
    Sessions.send(@client_id, error)
    false
  end

end
