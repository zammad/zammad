class RecentViewedController < ApplicationController
  before_filter :authentication_check

  # GET /recent_viewed
  def recent_viewed
    recent_viewed = History.recent_viewed(current_user)

    # get related users
    users = {}
    tickets = []
    recent_viewed.each {|item|

      # load article ids
#      if item.history_object == 'Ticket'
        tickets.push Ticket.find( item['o_id'] ).attributes
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
  
end