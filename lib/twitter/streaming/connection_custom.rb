# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# file is based on Twitter::Streaming::Connection, needed to get custom_connection_handle
# to close connection after config has changed
class Twitter::Streaming::ConnectionCustom < Twitter::Streaming::Connection

  def stream(request, response)
    client_context = OpenSSL::SSL::SSLContext.new
    @client = @tcp_socket_class.new(Resolv.getaddress(request.uri.host), request.uri.port)
    ssl_client = @ssl_socket_class.new(@client, client_context)

    ssl_client.connect
    request.stream(ssl_client)
    while body = ssl_client.readpartial(1024) # rubocop:disable Lint/AssignmentInCondition
      response << body
    end
  end

  def custom_connection_handle
    @client
  end

end
