# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

# file is based on Twitter::Streaming::Client, needed to get custom_connection_handle
# to close connection after config has changed

class Twitter::Streaming::ClientCustom < Twitter::Streaming::Client

  def initialize(options = {})
    super
    @connection = Twitter::Streaming::ConnectionCustom.new(options)
  end

  def custom_connection_handle
    @connection.custom_connection_handle
  end

end
