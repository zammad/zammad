class TicketOverviewsController < ApplicationController
  before_filter :authentication_check

  # GET /tickets
  def show
#sleep 2

    # get navbar overview data
    if !params[:view]
      result = Ticket.overview(
        :current_user_id => current_user.id,
      )
      render :json => result
      return
    end

    # get real overview data
    if params[:array]
      overview = Ticket.overview(
        :view            => params[:view],
        :current_user_id => current_user.id,
        :array           => true,
      ) 
      tickets = []
      overview[:tickets].each {|ticket|
        data = { :id => ticket.id }
        tickets.push data
      }

      # return result
      render :json => {
        :overview      => overview[:overview],
        :tickets       => tickets,
        :tickets_count => overview[:tickets_count],
      }
      return      
    end
    overview = Ticket.overview(
      :view            => params[:view],
      :view_mode       => params[:view_mode],
      :current_user_id => current_user.id,
      :start_page      => params[:start_page],
    )
 
    # get related users
    users = {}
    tickets = []
    overview[:tickets].each {|ticket|
      tickets.push ticket.attributes
      if !users[ ticket.owner_id ]
        users[ ticket.owner_id ] = User.user_data_full( ticket.owner_id )
      end
      if !users[ ticket.customer_id ]
        users[ ticket.customer_id ] = User.user_data_full( ticket.customer_id )
      end
      if !users[ ticket.created_by_id ]
        users[ ticket.created_by_id ] = User.user_data_full( ticket.created_by_id )
      end
    }

    # get data for bulk action
    bulk_owners = Role.where( :name => ['Agent'] ).first.users.select(:id).where( :active => true ).uniq()
    bulk_owner_ids = []
    bulk_owners.each { |user|
      bulk_owner_ids.push user.id
      if !users[ user.id ]
        users[ user.id ] = User.user_data_full( user.id )
      end
    }

    # return result
    render :json => {
      :overview      => overview[:overview],
      :tickets       => tickets,
      :tickets_count => overview[:tickets_count],
      :users         => users,
      :bulk          => {
        :owner_id => {
          :id => bulk_owner_ids,
        },
      },
    }
  end


  # GET /ticket_create/1
  def ticket_create

    # get attributes
    (users, ticket_owner_ids, ticket_group_ids, ticket_state_ids, ticket_priority_ids) = Ticket.create_attributes(
        :current_user_id => current_user.id,
    )

    # split data
    ticket = nil
    articles = nil
    if params[:ticket_id] && params[:article_id]
      ticket = Ticket.find( params[:ticket_id] )
      
      # get related users
      users = {}
      if !users[ticket.owner_id]
        users[ticket.owner_id] = User.user_data_full(ticket.owner_id)
      end
      if !users[ticket.customer_id]
        users[ticket.customer_id] = User.user_data_full(ticket.customer_id)
      end
      if !users[ticket.created_by_id]
        users[ticket.created_by_id] = User.user_data_full(ticket.created_by_id)
      end
  
      owner_ids = []
      ticket.agent_of_group.each { |user|
        owner_ids.push user.id
        if !users[user.id]
          users[user.id] = User.user_data_full(user.id)
        end
      }
  
      # get related articles
      ticket[:article_ids] = [ params[:article_id] ]
        
      article = Ticket::Article.find( params[:article_id] )
        
      # add attachment list to article
      article['attachments'] = Store.list( :object => 'Ticket::Article', :o_id => article.id )
        
      # load users
      if !users[article.created_by_id]
        users[article.created_by_id] = User.user_data_full(article.created_by_id)
      end
    end

    # return result
    render :json => {
      :ticket   => ticket,
      :articles => [ article ],
      :users    => users,
      :edit_form => {
        :owner_id => {
          :id => ticket_owner_ids
        },
        :group_id => {
          :id => ticket_group_ids
        },
        :ticket_state_id => {
          :id => ticket_state_ids
        },
        :ticket_priority_id => {
          :id => ticket_priority_ids
        }
      }
    }
  end

  # GET /ticket_full/1
  def ticket_full
    ticket = Ticket.find(params[:id])

    # get related users
    users = {}
    if !users[ticket.owner_id]
      users[ticket.owner_id] = User.user_data_full(ticket.owner_id)
    end
    if !users[ticket.customer_id]
      users[ticket.customer_id] = User.user_data_full(ticket.customer_id)
    end
    if !users[ticket.created_by_id]
      users[ticket.created_by_id] = User.user_data_full(ticket.created_by_id)
    end

    owner_ids = []
    ticket.agent_of_group.each { |user|
      owner_ids.push user.id
      if !users[user.id]
        users[user.id] = User.user_data_full(user.id)
      end
    }

    # get related articles
    ticket[:article_ids] = []
    articles = ticket.articles || []
    
    # get related users
    articles.each {|article|
      
      # load article ids
      ticket[:article_ids].push article.id
      
      # add attachment list to article
      article['attachments'] = Store.list( :object => 'Ticket::Article', :o_id => article.id )
      
      # load users
      if !users[article.created_by_id]
        users[article.created_by_id] = User.user_data_full(article.created_by_id)
      end
    }

    # log object as viewed
    log_view(ticket)

    # return result
    render :json => {
      :ticket   => ticket,
      :articles => articles,
      :users    => users,
      :edit_form => {
        :owner_id => {
          :id => owner_ids
        }
      }
    }
  end

  # POST /ticket_attachment/new
  def ticket_attachment_new
#    puts '-------'
#    puts params.inspect

    # store file
#    content_type = request.content_type
    content_type = request[:content_type]
    puts 'content_type: ' + content_type.inspect
    if !content_type || content_type == 'application/octet-stream'
      if MIME::Types.type_for(params[:qqfile]).first
        content_type = MIME::Types.type_for(params[:qqfile]).first.content_type
      else
        content_type = 'application/octet-stream'
      end
    end
    headers_store = {
      'Content-Type' => content_type
    }
    Store.add(
      :object      => 'UploadCache::' + params[:form] + '::' + current_user.id.to_s,
      :o_id        => params[:form_id],
      :data        => request.body.read,
      :filename    => params[:qqfile],
      :preferences => headers_store
    )

    # return result
    render :json => {
      :success  => true,
    }
  end
  
  # GET /ticket_attachment/1
  def ticket_attachment
    
    # permissin check
    
    # find file
    file = Store.find(params[:id])
    send_data(
      file.store_file.data,
      :filename    => file.filename,
      :type        => file.preferences['Content-Type'] || file.preferences['Mime-Type'],
      :disposition => 'inline'
    )
  end

  # GET /ticket_article_plain/1
  def ticket_article_plain
    
    # permissin check
    list = Store.list(
      :object => 'Ticket::Article::Mail',
      :o_id   => params[:id],
    )
    # find file
    if list
      file = Store.find(list.first)
      send_data(
        file.store_file.data,
        :filename    => file.filename,
        :type        => 'message/rfc822',
        :disposition => 'inline'
      )
    end
  end

  # GET /ticket_customer
  # GET /tickets_customer
  def ticket_customer
    
    # get closed/open states
    ticket_state_list_open   = Ticket::State.where(
      :ticket_state_type_id => Ticket::StateType.where(:name => ['new','open', 'pending remidner', 'pending action'])
    )
    ticket_state_list_closed = Ticket::State.where(
      :ticket_state_type_id => Ticket::StateType.where(:name => ['closed'] )
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
    ticket = Ticket.find(params[:id])
    
    # get history of ticket
    history = History.history_list( 'Ticket', params[:id], 'Ticket::Article' )

    # get related users
    users = {}
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

    # check slave ticket
    ticket_slave = Ticket.where( :id => params[:slave_ticket_id] ).first
    if !ticket_slave
      render :json => {
        :result  => 'faild',
        :message => 'No such slave ticket!',
      }
      return
    end

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
    
  # GET /user_search
  def user_search
    
    # get params
    query = params[:term]
    limit = params[:limit] || 18

    # do query
    user_all = User.find(
      :all,
      :limit      => limit,
      :conditions => ['firstname LIKE ? or lastname LIKE ? or email LIKE ?', "%#{query}%", "%#{query}%", "%#{query}%"],
      :order      => 'firstname'
    )
    
    # build result list
    users = []
    user_all.each do |user|
      realname = user.firstname.to_s + ' ' + user.lastname.to_s
      if user.email && user.email.to_s != ''
        realname = realname + ' <' +  user.email.to_s + '>'
      end
      a = { :id => user.id, :label => realname, :value => realname }
      users.push a
    end

    # return result
    render :json => users
  end
end