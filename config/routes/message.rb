module ExtraRoutes
  def add(map)

    # messages
    map.match '/api/message_send',                :to => 'long_polling#message_send', :via => [ :get, :post ]
    map.match '/api/message_receive',             :to => 'long_polling#message_receive', :via => [ :get, :post ]

  end
  module_function :add
end
