class Sessions::Event::Broadcast < Sessions::Event::Base

  def run

    # list all current clients
    client_list = Sessions.list
    client_list.each { |local_client_id, local_client|
      if local_client_id == @client_id
        log 'notice', 'do not send broadcast to it self'
        next
      end

      # broadcast to recipient list
      if @payload['recipient']
        if @payload['recipient'].class != Hash && @payload['recipient'].class != ActiveSupport::HashWithIndifferentAccess && @payload['recipient'].class != ActionController::Parameters
          log 'error', "recipient attribute isn't a hash (#{@payload['recipient'].class}) '#{@payload['recipient'].inspect}'"
        elsif !@payload['recipient'].key?('user_id')
          log 'error', "need recipient.user_id attribute '#{@payload['recipient'].inspect}'"
        elsif @payload['recipient']['user_id'].class != Array
          log 'error', "recipient.user_id attribute isn't an array '#{@payload['recipient']['user_id'].inspect}'"
        else
          @payload['recipient']['user_id'].each { |user_id|

            next if local_client[:user]['id'].to_i != user_id.to_i

            log 'notice', "send broadcast from (#{@client_id}) to (user_id=#{user_id})", local_client_id
            websocket_send(local_client_id, @payload['data'])
          }
        end

        # broadcast every client
      else
        log 'notice', "send broadcast from (#{@client_id})", local_client_id
        websocket_send(local_client_id, @payload['data'])
      end
    }

    false
  end

end
