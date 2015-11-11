class Sessions::Event::ChatBase

  def initialize(data, session, client_id)
    @data = data
    @session = session
    @client_id = client_id

  end

  def pre_check

    # check if feature is enabled
    if !Setting.get('chat')
      return {
        event: 'chat_error',
        data: {
          state: 'chat_disabled',
        },
      }
    end

    false
  end

end
