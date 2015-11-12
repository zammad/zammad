class Sessions::Event::ChatBase

  def initialize(data, session, client_id)
    @data = data
    @session = session
    @client_id = client_id

  end

  def pre

    # check if feature is enabled
    return if Setting.get('chat')
    {
      event: 'chat_error',
      data: {
        state: 'chat_disabled',
      },
    }
  end

  def post
    false
  end

end
