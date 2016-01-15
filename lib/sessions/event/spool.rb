class Sessions::Event::Spool < Sessions::Event::Base

  # get spool messages and send them to new client connection
  def run

    # error handling
    if @payload['timestamp']
      log 'notice', "request spool data > '#{Time.at(@payload['timestamp']).utc.iso8601}'"
    else
      log 'notice', 'request spool with init data'
    end

    if !@session || !@session['id']
      log 'error', "can't send spool, session not authenticated"
      return
    end

    spool = Sessions.spool_list(@payload['timestamp'], @session['id'])
    spool.each { |item|

      # create new msg to push to client
      if item[:type] == 'direct'
        log 'notice', "send spool to (user_id=#{@session['id']})"
      else
        log 'notice', 'send spool'
      end
      websocket_send(@client_id, item[:message])
    }

    # send spool:sent event to client
    log 'notice', 'send spool:sent event'
    {
      event: 'spool:sent',
      data: {
        timestamp: Time.now.utc.to_i,
      },
    }
  end

end
