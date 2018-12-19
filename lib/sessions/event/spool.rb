class Sessions::Event::Spool < Sessions::Event::Base

=begin

Event module to serve spool messages and send them to new client connection.

To execute this manually, just paste the following into the browser console

  App.WebSocket.send({event:'spool'})

=end

  def run

    # error handling
    if @payload['timestamp']
      log 'notice', "request spool data > '#{Time.at(@payload['timestamp']).utc.iso8601}'"
    else
      log 'notice', 'request spool with init data'
    end

    if !@session || !@session['id']
      log 'error', "Can't send spool, session not authenticated"
      return {
        event: 'error',
        data:  {
          error: 'Can\'t send spool, session not authenticated',
        },
      }
    end

    spool = Sessions.spool_list(@payload['timestamp'], @session['id'])
    spool.each do |item|

      # create new msg to push to client
      if item[:type] == 'direct'
        log 'notice', "send spool to (user_id=#{@session['id']})"
      else
        log 'notice', 'send spool'
      end
      websocket_send(@client_id, item[:message])
    end

    # send spool:sent event to client
    log 'notice', 'send spool:sent event'
    {
      event: 'spool:sent',
      data:  {
        timestamp: Time.now.utc.to_i,
      },
    }
  end

end
