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
    map.match '/activity_stream',       :to => 'ticket_overviews#activity_stream'
    map.match '/recent_viewed',         :to => 'ticket_overviews#recent_viewed'
    map.match '/ticket_create',         :to => 'ticket_overviews#ticket_create'
    map.match '/user_search',           :to => 'ticket_overviews#user_search'

  end
  module_function :add
end