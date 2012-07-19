module ExtraRoutes
  def add(map)

    # tickets
    map.resources :channels,            :only => [:create, :show, :index, :update, :destroy]
    map.resources :ticket_articles,     :only => [:create, :show, :index, :update]
    map.resources :ticket_priorities,   :only => [:create, :show, :index, :update]
    map.resources :ticket_states,       :only => [:create, :show, :index, :update]
    map.resources :tickets,             :only => [:create, :show, :index, :update]
    map.match '/ticket_full/:id',       :to => 'ticket_overviews#ticket_full'
    map.match '/ticket_attachment/:id', :to => 'ticket_overviews#ticket_attachment'
    map.match '/ticket_attachment_new', :to => 'ticket_overviews#ticket_attachment_new'
    map.match '/ticket_article_plain/:id', :to => 'ticket_overviews#ticket_article_plain'
    map.match '/ticket_history/:id',    :to => 'ticket_overviews#ticket_history'
    map.match '/ticket_customer',       :to => 'ticket_overviews#ticket_customer'
    map.match '/ticket_overviews',      :to => 'ticket_overviews#show'
    map.match '/ticket_create',         :to => 'ticket_overviews#ticket_create'
    map.match '/user_search',           :to => 'ticket_overviews#user_search'

    map.match '/ticket_merge/:slave_ticket_id/:master_ticket_number', :to => 'ticket_overviews#ticket_merge'

    map.match '/activity_stream',       :to => 'activity#activity_stream'
    map.match '/recent_viewed',         :to => 'recent_viewed#recent_viewed'

  end
  module_function :add
end