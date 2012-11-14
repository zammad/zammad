class TicketsController < ApplicationController
  before_filter :authentication_check

  # GET /tickets
  def index
    @tickets = Ticket.all

    render :json => @tickets
  end

  # GET /tickets/1
  def show
    @ticket = Ticket.find( params[:id] )

    # permissin check
    return if !ticket_permission(@ticket)

    render :json => @ticket
  end

  # POST /tickets
  def create
    @ticket = Ticket.new( params[:ticket] )
    @ticket.updated_by_id = current_user.id
    @ticket.created_by_id = current_user.id

    # check if article is given
    if !params[:article]
      render :json => 'article hash is missing', :status => :unprocessable_entity
      return
    end

    # create ticket
    if !@ticket.save
      render :json => @ticket.errors, :status => :unprocessable_entity
      return
    end

    # create article if given
    if params[:article]
      @article = Ticket::Article.new(params[:article])
      @article.created_by_id = params[:article][:created_by_id] || current_user.id
      @article.updated_by_id = params[:article][:updated_by_id] || current_user.id
      @article.ticket_id     = @ticket.id

      # find attachments in upload cache
      @article['attachments'] = Store.list(
        :object => 'UploadCache::TicketZoom::' + current_user.id.to_s,
        :o_id => @article.ticket_id
      )
      if !@article.save
        render :json => @article.errors, :status => :unprocessable_entity
        return
      end
      
      # remove attachments from upload cache
      Store.remove(
        :object => 'UploadCache::TicketZoom::' + current_user.id.to_s,
        :o_id   => @article.ticket_id
      )
    end

    render :json => @ticket, :status => :created
  end

  # PUT /tickets/1
  def update
    @ticket = Ticket.find(params[:id])

    # permissin check
    return if !ticket_permission(@ticket)

    params[:ticket][:updated_by_id] = current_user.id

    if @ticket.update_attributes( params[:ticket] )
      render :json => @ticket, :status => :ok
    else
      render :json => @ticket.errors, :status => :unprocessable_entity
    end
  end

  # DELETE /tickets/1
  def destroy
    @ticket = Ticket.find( params[:id] )

    # permissin check
    return if !ticket_permission(@ticket)

    @ticket.destroy

    head :ok
  end

  # GET /ticket_customer
  # GET /tickets_customer
  def ticket_customer

    # get closed/open states
    ticket_state_list_open   = Ticket::State.where(
      :ticket_state_type_id => Ticket::StateType.where( :name => ['new','open', 'pending reminder', 'pending action'] )
    )
    ticket_state_list_closed = Ticket::State.where(
      :ticket_state_type_id => Ticket::StateType.where( :name => ['closed'] )
    )

    # get tickets
    tickets_open = Ticket.where(
      :customer_id     => params[:customer_id],
      :ticket_state_id => ticket_state_list_open
    ).limit(15).order('created_at DESC')

    tickets_closed = Ticket.where(
      :customer_id     => params[:customer_id],
      :ticket_state_id => ticket_state_list_closed
    ).limit(15).order('created_at DESC')

#    tickets = Ticket.where(:customer_id => user_id).limit(15).order('created_at DESC')
#    ticket_items = []
#    tickets.each do |ticket|
#      style = ''
#      ticket_state_type = ticket.ticket_state.ticket_state_type.name
#      if ticket_state_type == 'closed' || ticket_state_type == 'merged'
#        style = 'text-decoration: line-through'
#      end
#      item = {
#        :url   => '#ticket/zoom/' + ticket.id.to_s,
#        :name  => 'T:' + ticket.number.to_s,
#        :title => ticket.title,
#        :style => style
#      }
#      ticket_items.push item
#    end
#    if ticket_items[0]
#      topic = {
#        :title => 'Tickets',
#        :items => ticket_items
#      }
#      user['links'].push topic
#    end

    # return result
    render :json => {
      :tickets => {
        :open   => tickets_open,
        :closed => tickets_closed
      }
#          :users => users,
    }
  end

  # GET /ticket_history/1
  def ticket_history

    # get ticket data
    ticket = Ticket.find( params[:id] )

    # permissin check
    return if !ticket_permission( ticket )

    # get history of ticket
    history = History.history_list( 'Ticket', params[:id], 'Ticket::Article' )

    # get related users
    users = {}
    users[ ticket.owner_id ] = User.user_data_full( ticket.owner_id )
    users[ ticket.customer_id ] = User.user_data_full( ticket.customer_id )
    history.each do |item|
      users[ item['created_by_id'] ] = User.user_data_full( item['created_by_id'] )
      if item['history_object'] == 'Ticket::Article'
        item['type'] = 'Article ' + item['type'].to_s
      else
        item['type'] = 'Ticket ' + item['type'].to_s
      end
    end

    # fetch meta relations
    history_objects    = History::Object.all()
    history_types      = History::Type.all()
    history_attributes = History::Attribute.all()

    # return result
    render :json => {
      :ticket             => ticket,
      :users              => users,
      :history            => history,
      :history_objects    => history_objects,
      :history_types      => history_types,
      :history_attributes => history_attributes
    }
  end

  # GET /ticket_merge_list/1
  def ticket_merge_list

    # get closed/open states
    ticket_states   = Ticket::State.where(
      :ticket_state_type_id => Ticket::StateType.where( :name => ['new','open', 'pending reminder', 'pending action', 'closed'] )
    )
    ticket = Ticket.find( params[:ticket_id] )
    ticket_list = Ticket.where( :customer_id => ticket.customer_id, :ticket_state_id => ticket_states )
      .where( 'id != ?', [ ticket.id ] )
      .order('created_at DESC')
      .limit(6)

    # get related users
    users = {}
    tickets = []
    ticket_list.each {|ticket|
      data = Ticket.full_data(ticket.id)
      tickets.push data
      if !users[ data['owner_id'] ]
        users[ data['owner_id'] ] = User.user_data_full( data['owner_id'] )
      end
      if !users[ data['customer_id'] ]
        users[ data['customer_id'] ] = User.user_data_full( data['customer_id'] )
      end
      if !users[ data['created_by_id'] ]
        users[ data['created_by_id'] ] = User.user_data_full( data['created_by_id'] )
      end
    }

    recent_viewed = History.recent_viewed_fulldata( current_user, 8 )

    # return result
    render :json => {
      :customer => {
        :tickets       => tickets,
        :users         => users,
      },
      :recent => recent_viewed
    }
  end

  # GET /ticket_merge/1/1
  def ticket_merge

    # check master ticket
    ticket_master = Ticket.where( :number => params[:master_ticket_number] ).first
    if !ticket_master
      render :json => {
        :result  => 'faild',
        :message => 'No such master ticket number!',
      }
      return
    end

    # permissin check
    return if !ticket_permission(ticket_master)

    # check slave ticket
    ticket_slave = Ticket.where( :id => params[:slave_ticket_id] ).first
    if !ticket_slave
      render :json => {
        :result  => 'faild',
        :message => 'No such slave ticket!',
      }
      return
    end

    # permissin check
    return if !ticket_permission( ticket_slave )

    # check diffetent ticket ids
    if ticket_slave.id == ticket_master.id
      render :json => {
        :result  => 'faild',
        :message => 'Can\'t merge ticket with it self!',
      }
      return
    end
      
    # merge ticket
    success = ticket_slave.merge_to(
      {
        :ticket_id     => ticket_master.id,
        :created_by_id => current_user.id,
       }
     )

    # return result
    render :json => {
      :result        => 'success',
      :master_ticket => ticket_master.attributes,
      :slave_ticket  => ticket_slave.attributes,
    }
  end

  # GET /ticket_full/1
  def ticket_full

    # permission check
    ticket = Ticket.find( params[:id] )
    return if !ticket_permission( ticket )

    # get related users
    users = {}
    if !users[ticket.owner_id]
      users[ticket.owner_id] = User.user_data_full( ticket.owner_id )
    end
    if !users[ticket.customer_id]
      users[ticket.customer_id] = User.user_data_full( ticket.customer_id )
    end
    if !users[ticket.created_by_id]
      users[ticket.created_by_id] = User.user_data_full( ticket.created_by_id )
    end

    owner_ids = []
    ticket.agent_of_group.each { |user|
      owner_ids.push user.id
      if !users[user.id]
        users[user.id] = User.user_data_full( user.id )
      end
    }

    # log object as viewed
    log_view( ticket )

    # get signature
    signature = {}
    if ticket.group.signature
      signature = ticket.group.signature.attributes

      # replace tags
      signature['body'] = NotificationFactory.build(
        :string  => signature['body'],
        :objects => {
          :ticket   => ticket,
          :user     => current_user,
        }
      )
    end

    # get related articles
    ticket = ticket.attributes
    ticket[:article_ids] = []
    articles = Ticket::Article.where( :ticket_id => params[:id] )

    # get related users
    articles_used = []
    articles.each {|article|

      # ignore internal article if customer is requesting
      next if article.internal == true && is_role('Customer')
      article_tmp = article.attributes

      # load article ids
      ticket[:article_ids].push article_tmp['id']
      
      # add attachment list to article
      article_tmp['attachments'] = Store.list( :object => 'Ticket::Article', :o_id => article.id )

      # remember article
      articles_used.push article_tmp

      # load users
      if !users[article.created_by_id]
        users[article.created_by_id] = User.user_data_full( article.created_by_id )
      end
    }

    # get groups
    group_ids = []
    Group.where( :active => true ).each { |group|
      group_ids.push group.id
    }
    agents = {}
    Ticket.agents.each { |user|
      agents[ user.id ] = 1
    }
    groups_users = {}
    group_ids.each {|group_id|
        groups_users[ group_id ] = []
        Group.find(group_id).users.each {|user|
            next if !agents[ user.id ]
            groups_users[ group_id ].push user.id
            if !users[user.id]
              users[user.id] = User.user_data_full( user.id )
            end
        }
    }

    # return result
    render :json => {
      :ticket    => ticket,
      :articles  => articles_used,
      :signature => signature,
      :users     => users,
      :edit_form => {
        :group_id__owner_id => groups_users,
        :owner_id           => owner_ids,
      }
    }
  end

  # GET /ticket_create/1
  def ticket_create

    # get attributes
    create_attributes = Ticket.create_attributes(
        :current_user_id => current_user.id,
    )

    # split data
    ticket = nil
    articles = nil
    users = {}
    if params[:ticket_id] && params[:article_id]
      ticket = Ticket.find( params[:ticket_id] )

      # get related users
      if !users[ticket.owner_id]
        users[ticket.owner_id] = User.user_data_full( ticket.owner_id )
      end
      if !users[ticket.customer_id]
        users[ticket.customer_id] = User.user_data_full( ticket.customer_id )
      end
      if !users[ticket.created_by_id]
        users[ticket.created_by_id] = User.user_data_full( ticket.created_by_id )
      end

      owner_ids = []
      ticket.agent_of_group.each { |user|
        owner_ids.push user.id
        if !users[user.id]
          users[user.id] = User.user_data_full( user.id )
        end
      }
  
      # get related articles
      ticket[:article_ids] = [ params[:article_id] ]

      article = Ticket::Article.find( params[:article_id] )

      # add attachment list to article
      article['attachments'] = Store.list( :object => 'Ticket::Article', :o_id => article.id )

      # load users
      if !users[article.created_by_id]
        users[article.created_by_id] = User.user_data_full( article.created_by_id )
      end
    end

    create_attributes[:owner_id].each {|user_id|
      if !users[user_id]
        users[user_id] = User.user_data_full( user_id )
      end
    }

    # return result
    render :json => {
      :ticket    => ticket,
      :articles  => [ article ],
      :users     => users,
      :edit_form => create_attributes,
    }
  end

  # GET /api/tickets/search
  def search
    
    # get params
    query = params[:term]
    limit = params[:limit] || 15

    conditions = []
    if current_user.is_role('Agent')
      group_ids = Group.select( 'groups.id' ).joins(:users).
        where( 'groups_users.user_id = ?', current_user.id ).
        where( 'groups.active = ?', true ).
        map( &:id )
      conditions = [ 'group_id IN (?)', group_ids ]
    else
      if !current_user.organization || !current_user.organization.shared
        conditions = [ 'customer_id = ?', current_user.id ]
      else
        conditions = [ '( customer_id = ? OR organization_id = ? )', current_user.id, current_user.organization.shared ]
      end
    end

    # do query
    tickets_all = Ticket.select('DISTINCT(tickets.id)').
      where(conditions).
      where( '( title LIKE ? OR number LIKE ? OR ticket_articles.body LIKE ? OR ticket_articles.from LIKE ? OR ticket_articles.to LIKE ? OR ticket_articles.subject LIKE ?)', "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%" ).
      joins(:articles).
      limit(limit).
      order('tickets.created_at DESC')

    # build result list
    tickets = []
    users = {}
    tickets_all.each do |ticket|
      ticket_tmp = Ticket.full_data(ticket.id)
      tickets.push ticket_tmp
      users[ ticket['owner_id'] ] = User.user_data_full( ticket_tmp['owner_id'] )
      users[ ticket['customer_id'] ] = User.user_data_full( ticket_tmp['customer_id'] )
      users[ ticket['created_by_id'] ] = User.user_data_full( ticket_tmp['created_by_id'] )
    end

    # return result
    render :json => {
      :tickets => tickets,
      :users   => users,
    }
  end


end
