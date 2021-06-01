# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# file is based on Twitter::Streaming::Client, needed to get custom_connection_handle
# to close connection after config has changed
require_dependency 'twitter/streaming/connection_custom'

class Twitter::Streaming::ClientCustom < Twitter::Streaming::Client

  def initialize(options = {})
    super
    @connection = Twitter::Streaming::ConnectionCustom.new(options)
  end

  def custom_connection_handle
    @connection.custom_connection_handle
  end

end
