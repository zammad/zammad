module ExtraRoutes
  def add(map)

    # messages
    map.match '/api/message_send',                :to => 'long_polling#message_send'
    map.match '/api/message_receive',             :to => 'long_polling#message_receive'

  end
  module_function :add
end