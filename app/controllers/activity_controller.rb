class ActivityController < ApplicationController
  before_filter :authentication_check

  # GET /activity_stream
  def activity_stream
    activity_stream = History.activity_stream(current_user, params[:limit])

    # get related users
    users = {}
    tickets = []
    articles = []
    activity_stream.each {|item|

      # load article ids
      if item['history_object'] == 'Ticket'
        ticket = Ticket.find( item['o_id'] ).attributes
        tickets.push ticket

        # load users
        if !users[ ticket['owner_id'] ]
          users[ ticket['owner_id'] ] = user_data_full( ticket['owner_id'] )
        end
        if !users[ ticket['customer_id'] ]
          users[ ticket['customer_id'] ] = user_data_full( ticket['customer_id'] )
        end
      end
      if item['history_object'] == 'Ticket::Article'
        article = Ticket::Article.find( item['o_id'] ).attributes
        if !article['subject'] || article['subject'] == ''
          article['subject'] = Ticket.find( article['ticket_id'] ).title
        end
        articles.push article

        # load users
        if !users[ article['created_by_id'] ]
          users[ article['created_by_id'] ] = user_data_full( article['created_by_id'] )
        end
      end
      if item['history_object'] == 'User'
        users[ item['o_id'] ] = user_data_full( item['o_id'] )
      end
          
      # load users
      if !users[ item['created_by_id'] ]
        users[ item['created_by_id'] ] = user_data_full( item['created_by_id'] )
      end
    }

    # return result
    render :json => {
      :activity_stream => activity_stream,
      :tickets         => tickets,
      :articles        => articles,
      :users           => users,
    }
  end

end