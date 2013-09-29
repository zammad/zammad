# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

class TicketsController < ApplicationController
  before_filter :authentication_check

  # GET /api/v1/tickets
  def index
    @tickets = Ticket.all

    render :json => @tickets
  end

  # GET /api/v1/tickets/1
  def show
    @ticket = Ticket.find( params[:id] )

    # permissin check
    return if !ticket_permission(@ticket)

    render :json => @ticket
  end

  # POST /api/v1/tickets
  def create
    @ticket = Ticket.new( Ticket.param_validation( params[:ticket] ) )

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

    # create tags if given
    if params[:tags] && !params[:tags].empty?
      tags = params[:tags].split /,/
      tags.each {|tag|
        Tag.tag_add(
          :object        => 'Ticket',
          :o_id          => @ticket.id,
          :item          => tag,
          :created_by_id => current_user.id,
        )
      }
    end

    # create article if given
    if params[:article]
      form_id  = params[:article][:form_id]
      params[:article].delete(:form_id)
      @article = Ticket::Article.new( Ticket::Article.param_validation( params[:article] ) )
      @article.ticket_id     = @ticket.id

      # find attachments in upload cache
      if form_id
        @article.attachments = Store.list(
          :object => 'UploadCache',
          :o_id   => form_id,
        )
      end
      if !@article.save
        render :json => @article.errors, :status => :unprocessable_entity
        return
      end

      # remove attachments from upload cache
      if form_id
        Store.remove(
          :object => 'UploadCache',
          :o_id   => form_id,
        )
      end
    end

    render :json => @ticket, :status => :created
  end

  # PUT /api/v1/tickets/1
  def update
    @ticket = Ticket.find(params[:id])

    # permissin check
    return if !ticket_permission(@ticket)

    if @ticket.update_attributes( Ticket.param_validation( params[:ticket] ) )
      render :json => @ticket, :status => :ok
    else
      render :json => @ticket.errors, :status => :unprocessable_entity
    end
  end

  # DELETE /api/v1/tickets/1
  def destroy
    @ticket = Ticket.find( params[:id] )

    # permissin check
    return if !ticket_permission(@ticket)

    @ticket.destroy

    head :ok
  end

  # GET /api/v1/ticket_customer
  # GET /api/v1/tickets_customer
  def ticket_customer

    # return result
    result = Ticket::ScreenOptions.list_by_customer(
      :customer_id => params[:customer_id],
      :limit       => 15,
    )
    render :json => {
      :tickets => result
    }
  end

  # GET /api/v1/ticket_history/1
  def ticket_history

    # get ticket data
    ticket = Ticket.find( params[:id] )

    # permissin check
    return if !ticket_permission( ticket )

    # get history of ticket
    history = ticket.history_get(true)


    # return result
    render :json => history
  end

  # GET /api/v1/ticket_merge_list/1
  def ticket_merge_list

    ticket = Ticket.find( params[:ticket_id] )
    assets = ticket.assets({})

    # open tickets by customer
    ticket_list = Ticket.where(
      :customer_id     => ticket.customer_id,
      :ticket_state_id => Ticket::State.by_category( 'open' )
    )
    .where( 'id != ?', [ ticket.id ] )
    .order('created_at DESC')
    .limit(6)

    # get related assets
    ticket_ids_by_customer = [] 
    ticket_list.each {|ticket|
      ticket_ids_by_customer.push ticket.id
      assets = ticket.assets(assets)
    }


    ticket_ids_recent_viewed = []
    ticket_recent_view = RecentView.list( current_user, 8 )
    ticket_recent_view.each {|item|
      if item['recent_view_object'] == 'Ticket'
        ticket_ids_recent_viewed.push item['o_id']
        ticket = Ticket.find( item['o_id'] )
        assets = ticket.assets(assets)
      end
    }

    # return result
    render :json => {
      :assets                   => assets,
      :ticket_ids_by_customer   => ticket_ids_by_customer,
      :ticket_ids_recent_viewed => ticket_ids_recent_viewed,
    }
  end

  # GET /api/v1/ticket_merge/1/1
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

  # GET /api/v1/ticket_full/1
  def ticket_full

    # permission check
    ticket = Ticket.find( params[:id] )
    return if !ticket_permission( ticket )

    # log object as viewed
    if !params[:do_not_log] || params[:do_not_log].to_i == 0
      log_view( ticket )
    end

    # get signature
    signature = {}
    if ticket.group.signature
      signature = ticket.group.signature.attributes

      # replace tags
      signature['body'] = NotificationFactory.build(
        :locale  => current_user.locale,
        :string  => signature['body'],
        :objects => {
          :ticket   => ticket,
          :user     => current_user,
        }
      )
    end

    # get related users
    assets = {}
    assets[ User.to_app_model ] = {}
    assets = ticket.assets(assets)

    # get attributes to update
    attributes_to_change = Ticket::ScreenOptions.attributes_to_change( :user => current_user, :ticket => ticket )

    attributes_to_change[:owner_id].each { |user_id|
      if !assets[ User.to_app_model ][user_id]
        assets[ User.to_app_model ][user_id] = User.user_data_full( user_id )
      end
    }

    attributes_to_change[:group_id__owner_id].each {|group_id, user_ids|
      user_ids.each {|user_id|
        if !assets[ User.to_app_model ][user_id]
          assets[ User.to_app_model ][user_id] = User.user_data_full( user_id )
        end
      }
    }

    # get related articles
    articles = Ticket::Article.where( :ticket_id => params[:id] )

    # get related users
    article_ids = []
    articles.each {|article|

      # ignore internal article if customer is requesting
      next if article.internal == true && is_role('Customer')

      # load article ids
      article_ids.push article.id

      # load assets
      assets = article.assets(assets)
    }

    # return result
    render :json => {
      :ticket_id          => ticket.id,
      :ticket_article_ids => article_ids,
      :signature          => signature,
      :assets             => assets,
      :edit_form          => attributes_to_change,
    }
  end

  # GET /api/v1/ticket_create/1
  def ticket_create

    # get attributes to update
    attributes_to_change = Ticket::ScreenOptions.attributes_to_change(
      :user       => current_user,
      #      :ticket_id  => params[:ticket_id],
      #      :article_id => params[:article_id]
    )

    assets = {}
    assets[ User.to_app_model ] = {}
    attributes_to_change[:owner_id].each { |user_id|
      if !assets[ User.to_app_model ][user_id]
        assets[ User.to_app_model ][user_id] = User.user_data_full( user_id )
      end
    }

    attributes_to_change[:group_id__owner_id].each {|group_id, user_ids|
      user_ids.each {|user_id|
        if !assets[ User.to_app_model ][user_id]
          assets[ User.to_app_model ][user_id] = User.user_data_full( user_id )
        end
      }
    }

    # split data
    split = {}
    if params[:ticket_id] && params[:article_id]
      ticket = Ticket.find( params[:ticket_id] )
      split[:ticket_id] = ticket.id
      assets = ticket.assets(assets)

      owner_ids = []
      ticket.agent_of_group.each { |user|
        owner_ids.push user.id
        if !assets[ User.to_app_model ][user.id]
          assets[ User.to_app_model ][user.id] = User.user_data_full( user.id )
        end
      }

      # get related articles
      article = Ticket::Article.find( params[:article_id] )
      split[:article_id] = article.id
      assets = article.assets(assets)
    end

    # return result
    render :json => {
      :split     => split,
      :assets    => assets,
      :edit_form => attributes_to_change,
    }
  end

  # GET /api/v1/tickets/search
  def search

    # build result list
    tickets = Ticket.search(
      :limit        => params[:limit],
      :query        => params[:term],
      :current_user => current_user,
    )
    assets = {}
    ticket_result = []
    tickets.each do |ticket|
      ticket_result.push ticket.id
      assets = ticket.assets(assets)
    end

    # return result
    render :json => {
      :tickets => ticket_result,
      :assets  => assets,
    }
  end

end
