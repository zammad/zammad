class TicketOverviewsController < ApplicationController
  before_filter :authentication_check

  # GET /tickets
  # GET /tickets.json
  def show
#sleep 2
    # build up attributes hash
    overview_selected     = nil
    overview_selected_raw = nil
    overviews             = Overview.all
    overviews.each { |overview|

      # for cleanup reasons, remove me later!
      overview.condition.each { |item, value |
        if item == 'owner_id' && overview.condition[item] != 1
          overview.condition[item] = 'current_user.id'
        end
      }
      
      # remember selected view
      if params[:view] && params[:view] == overview.meta[:url]
        overview_selected     = overview
        overview_selected_raw = Marshal.load( Marshal.dump(overview.attributes) )
      end

      # replace 'current_user.id' with current_user.id
      overview.condition.each { |item, value |
        if value == 'current_user.id'
          overview.condition[item] = current_user.id
        end
      }
    }

    # sortby
      # prio
      # state
      # group
      # customer
    
    # order
      # asc
      # desc
      
    # groupby
      # prio
      # state
      # group
      # customer    

#    all = attributes[:myopenassigned]
#    all.merge( { :group_id => groups } )

#    @tickets = Ticket.where(:group_id => groups, attributes[:myopenassigned] ).limit(params[:limit])
    # get only tickets with permissions
    group_ids = Group.select( 'groups.id' ).joins(:users).
      where( 'groups_users.user_id = ?', [current_user.id] ).
      where( 'groups.active = ?', true ).
      map( &:id )

    # overview meta for navbar
    if !overview_selected

      # loop each overview
      result = []
      overviews.each { |overview|

        # get count
        count = Ticket.where( :group_id => group_ids ).where( overview.condition ).count()
        
        # get meta info
        all = overview.meta
        
        # push to result data
        result.push all.merge( { :count => count } )
      }

      render :json => result
      return
    end

    # get tickets for overview
    params[:start_page] ||= 1
    tickets = Ticket.where( :group_id => group_ids ).
      where( overview_selected.condition ).
      order( overview_selected[:order][:by].to_s + ' ' + overview_selected[:order][:direction].to_s ).
      limit( overview_selected.view[ params[:view_mode].to_sym ][:per_page] ).
      offset( overview_selected.view[ params[:view_mode].to_sym ][:per_page].to_i * ( params[:start_page].to_i - 1 ) )

    tickets_count = Ticket.where( :group_id => group_ids ).
      where( overview_selected.condition ).
      count()

    # get related users
    users = {}
    tickets.each {|ticket|
      if !users[ticket.owner_id]
        users[ticket.owner_id] = user_data_full(ticket.owner_id)
      end
      if !users[ticket.customer_id]
        users[ticket.customer_id] = user_data_full(ticket.customer_id)
      end
      if !users[ticket.created_by_id]
        users[ticket.created_by_id] = user_data_full(ticket.created_by_id)
      end
    }

    # get data for bulk action
    bulk_owners = Role.where( :name => ['Agent'] ).first.users.select(:id).where( :active => true ).uniq()
    bulk_owner_ids = []
    bulk_owners.each { |user|
      bulk_owner_ids.push user.id
      if !users[user.id]
        users[user.id] = user_data_full(user.id)
      end
    }

    # return result
    render :json => {
      :overview      => overview_selected_raw,
      :tickets       => tickets,
      :tickets_count => tickets_count,
      :users         => users,
      :bulk          => {
        :owner_id => {
          :id => bulk_owner_ids,
        }
      },
    }
  end


  # GET /ticket_create
  # GET /ticket_create/1.json
  def ticket_create

    # get related users
    users = {}

    ticket_group_ids = []
    Group.where( :active => true ).each { |group|
      ticket_group_ids.push group.id
    }
    ticket_owner_ids = []
    Ticket.agents.each { |user|
      ticket_owner_ids.push user.id
      if !users[user.id]
        users[user.id] = user_data_full(user.id)
      end
    }

    ticket_state_ids = []
    Ticket::State.where( :active => true ).each { |state|
      ticket_state_ids.push state.id
    }
    ticket_priority_ids = []
    Ticket::Priority.where( :active => true ).each { |priority|
      ticket_priority_ids.push priority.id
    }

    # return result
    render :json => {
#          :ticket   => ticket,
#          :articles => articles,
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
  # GET /ticket_full/1.json
  def ticket_full
    ticket = Ticket.find(params[:id])

    # get related users
    users = {}
    if !users[ticket.owner_id]
      users[ticket.owner_id] = user_data_full(ticket.owner_id)
    end
    if !users[ticket.customer_id]
      users[ticket.customer_id] = user_data_full(ticket.customer_id)
    end
    if !users[ticket.created_by_id]
      users[ticket.created_by_id] = user_data_full(ticket.created_by_id)
    end

    owner_ids = []
    ticket.agent_of_group.each { |user|
      owner_ids.push user.id
      if !users[user.id]
        users[user.id] = user_data_full(user.id)
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
        users[article.created_by_id] = user_data_full(article.created_by_id)
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
      :type        => file.preferences['Mime-Type'] || file.preferences['Content-Type'],
      :disposition => 'inline'
    )
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
  # GET /tickets_history/1.json
  def ticket_history
    
    # get ticket data
    ticket = Ticket.find(params[:id])
    
    # get history of ticket
    history = History.history_list(['Ticket', 'Ticket::Article'], params[:id])

    # get related users
    users = {}
    history.each do |item|
      users[item.created_by_id] = user_data_full(item.created_by_id)
#      item['history_attribute'] = item.history_attribute
#      item['history_type'] = item.history_type
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
  
  # GET /activity_stream
  # GET /activity_stream.json
  def activity_stream
    activity_stream = History.activity_stream(current_user, params[:limit])

    # get related users
    users = {}
    tickets = []
    activity_stream.each {|item|

      # load article ids
#      if item.history_object == 'Ticket'
        tickets.push Ticket.find( item['o_id'] )
#      end
#      if item.history_object 'Ticket::Article'
#        tickets.push Ticket::Article.find(item.o_id)
#      end
#      if item.history_object 'User'
#        tickets.push User.find(item.o_id)
#      end
          
      # load users
      if !users[ item['created_by_id'] ]
        users[ item['created_by_id'] ] = user_data_full( item['created_by_id'] )
      end
    }

    # return result
    render :json => {
      :activity_stream => activity_stream,
      :tickets         => tickets,
      :users           => users,
    }
  end
  
  # GET /recent_viewed
  # GET /recent_viewed.json
  def recent_viewed
    recent_viewed = History.recent_viewed(current_user)

    # get related users
    users = {}
    tickets = []
    recent_viewed.each {|item|

      # load article ids
#      if item.history_object == 'Ticket'
        tickets.push Ticket.find( item['o_id'] )
#      end
#      if item.history_object 'Ticket::Article'
#        tickets.push Ticket::Article.find(item.o_id)
#      end
#      if item.history_object 'User'
#        tickets.push User.find(item.o_id)
#      end
          
      # load users
      if !users[ item['created_by_id'] ]
        users[ item['created_by_id'] ] = user_data_full( item['created_by_id'] )
      end
    }

    # return result
    render :json => {
      :recent_viewed => recent_viewed,
      :tickets       => tickets,
      :users         => users,
    }
  end
  
  # GET /user_search
  # GET /user_search.json
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