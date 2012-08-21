class LinksController < ApplicationController
  before_filter :authentication_check

  # GET /links
  def index
    links = Link.list(
      :link_object       => params[:link_object],
      :link_object_value => params[:link_object_value],
    )

    #
    tickets = []
    users = {}
    link_list = []
    links.each { |item|
      link_list.push item
      if item['link_object'] == 'Ticket'
        data = Ticket.full_data( item['link_object_value'] )
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
      end
    }

    # return result
    render :json => {
      :links    => link_list,
      :tickets  => tickets,
      :users    => users,
    }
  end

  # POST /links/add
  def add
#    @template.created_by_id = current_user.id
    link = Link.add(
      :link_type                => params[:link_type],
      :link_object_source       => params[:link_object_source],
      :link_object_source_value => params[:link_object_source_value],
      :link_object_target       => params[:link_object_target],
      :link_object_target_value => params[:link_object_target_value]
    )

    if link
      render :json => link, :status => :created
    else
      render :json => link.errors, :status => :unprocessable_entity
    end
  end

  # DELETE /links/delete
  def delete
    @template = Template.find(params[:id])

    if @template.update_attributes(params[:template])
      render :json => @template, :status => :ok
    else
      render :json => @template.errors, :status => :unprocessable_entity
    end
  end

end
