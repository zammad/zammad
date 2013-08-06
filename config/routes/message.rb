module ExtraRoutes
  def add(map, api_path)

    # messages
    map.match api_path + '/message_send',           :to => 'long_polling#message_send', :via => [ :get, :post ]
    map.match api_path + '/message_receive',        :to => 'long_polling#message_receive', :via => [ :get, :post ]

  end
  module_function :add
end
