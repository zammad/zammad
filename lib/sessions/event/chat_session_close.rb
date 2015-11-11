class Sessions::Event::ChatSessionClose < Sessions::Event::ChatBase

  def run

    if !@data['data'] || !@data['data']['session_id']
      return {
        event: 'chat_status_close',
        data: {
          state: 'Need session_id.',
        },
      }
    end

    chat_session = Chat::Session.find_by(session_id: @data['data']['session_id'])
    if !chat_session
      return {
        event: 'chat_status_close',
        data: {
          state: "No such session id #{data['data']['session_id']}",
        },
      }
    end

    chat_session.state = 'closed'
    chat_session.save

    # return new session
    {
      event: 'chat_status_close',
      data: {
        state: 'ok',
        session_id: chat_session.session_id,
      },
    }
  end
end
