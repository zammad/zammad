class TicketOverviewsController < ApplicationController
  before_filter :authentication_check

  # GET /tickets
  def show
#sleep 2

    # get navbar overview data
    if !params[:view]
      result = Ticket.overview(
        :current_user => current_user,
      )
      render :json => result
      return
    end

    # get real overview data
    if params[:array]
      overview = Ticket.overview(
        :view         => params[:view],
        :current_user => current_user,
        :array        => true,
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
      :array           => true,
    )
 
    # get related users
    users = {}
    tickets = []
    overview[:tickets].each {|ticket|
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
              users[user.id] = User.user_data_full(user.id)
            end
        }
    }

    # return result
    render :json => {
      :overview      => overview[:overview],
      :tickets       => tickets,
      :tickets_count => overview[:tickets_count],
      :users         => users,
      :bulk          => {
        :group_id__owner_id => groups_users,
      },
    }
  end

end