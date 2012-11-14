module ExtraRoutes
  def add(map)

    # tickets
    map.match '/api/tickets/search',                                :to => 'tickets#search',            :via => [:get, :post]
    map.match '/api/tickets',                                       :to => 'tickets#index',             :via => :get
    map.match '/api/tickets/:id',                                   :to => 'tickets#show',              :via => :get
    map.match '/api/tickets',                                       :to => 'tickets#create',            :via => :post
    map.match '/api/tickets/:id',                                   :to => 'tickets#update',            :via => :put
    map.match '/api/ticket_create',                                 :to => 'tickets#ticket_create',     :via => :get
    map.match '/api/ticket_full/:id',                               :to => 'tickets#ticket_full',       :via => :get
    map.match '/api/ticket_history/:id',                            :to => 'tickets#ticket_history',    :via => :get
    map.match '/api/ticket_customer',                               :to => 'tickets#ticket_customer',   :via => :get
    map.match '/api/ticket_merge_list/:ticket_id',                  :to => 'tickets#ticket_merge_list', :via => :get
    map.match '/api/ticket_merge/:slave_ticket_id/:master_ticket_number', :to => 'tickets#ticket_merge'

    # ticket overviews
    map.match '/api/ticket_overviews',                                  :to => 'ticket_overviews#show', :via => :get

    # ticket priority
    map.match '/api/ticket_priorities',                             :to => 'ticket_priorities#index',   :via => :get
    map.match '/api/ticket_priorities/:id',                         :to => 'ticket_priorities#show',    :via => :get
    map.match '/api/ticket_priorities',                             :to => 'ticket_priorities#create',  :via => :post
    map.match '/api/ticket_priorities/:id',                         :to => 'ticket_priorities#update',  :via => :put

    # ticket state
    map.match '/api/ticket_states',                                 :to => 'ticket_states#index',       :via => :get
    map.match '/api/ticket_states/:id',                             :to => 'ticket_states#show',        :via => :get
    map.match '/api/ticket_states',                                 :to => 'ticket_states#create',      :via => :post
    map.match '/api/ticket_states/:id',                             :to => 'ticket_states#update',      :via => :put

    # ticket articles
    map.match '/api/ticket_articles',                               :to => 'ticket_articles#index',     :via => :get
    map.match '/api/ticket_articles/:id',                           :to => 'ticket_articles#show',      :via => :get
    map.match '/api/ticket_articles',                               :to => 'ticket_articles#create',    :via => :post
    map.match '/api/ticket_articles/:id',                           :to => 'ticket_articles#update',    :via => :put
    map.match '/api/ticket_attachment/:ticket_id/:article_id/:id',  :to => 'ticket_articles#attachment'
    map.match '/api/ticket_attachment_new',                         :to => 'ticket_articles#attachment_new'
    map.match '/api/ticket_article_plain/:id',                      :to => 'ticket_articles#article_plain',  :via => :get

  end
  module_function :add
end