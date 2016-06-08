# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class TicketsController < ApplicationController
  before_action :authentication_check

  # GET /api/v1/tickets
  def index
    offset = 0
    per_page = 100

    if params[:page] && params[:per_page]
      offset = (params[:page].to_i - 1) * params[:per_page].to_i
      per_page = params[:per_page].to_i
    end

    access_condition = Ticket.access_condition(current_user)
    tickets = Ticket.where(access_condition).offset(offset).limit(per_page)

    if params[:expand]
      list = []
      tickets.each {|ticket|
        list.push ticket.attributes_with_relation_names
      }
      render json: list, status: :ok
      return
    end

    if params[:full]
      assets = {}
      item_ids = []
      tickets.each {|item|
        item_ids.push item.id
        assets = item.assets(assets)
      }
      render json: {
        record_ids: item_ids,
        assets: assets,
      }, status: :ok
      return
    end

    render json: tickets
  end

  # GET /api/v1/tickets/1
  def show

    # permission check
    ticket = Ticket.find(params[:id])
    return if !ticket_permission(ticket)

    if params[:expand]
      result = ticket.attributes_with_relation_names
      render json: result, status: :ok
      return
    end

    if params[:full]
      full = Ticket.full(params[:id])
      render json: full
      return
    end

    if params[:all]
      render json: ticket_all(ticket)
      return
    end

    render json: ticket
  end

  # POST /api/v1/tickets
  def create
    clean_params = Ticket.param_association_lookup(params)
    clean_params = Ticket.param_cleanup(clean_params, true)
    ticket = Ticket.new(clean_params)

    # check if article is given
    if !params[:article]
      render json: { error: 'article hash is missing' }, status: :unprocessable_entity
      return
    end

    # create ticket
    if !ticket.save
      render json: ticket.errors, status: :unprocessable_entity
      return
    end

    # create tags if given
    if params[:tags] && !params[:tags].empty?
      tags = params[:tags].split(/,/)
      tags.each {|tag|
        Tag.tag_add(
          object: 'Ticket',
          o_id: ticket.id,
          item: tag,
          created_by_id: current_user.id,
        )
      }
    end

    # create article if given
    if params[:article]
      article_create(ticket, params[:article])
    end

    if params[:expand]
      result = ticket.attributes_with_relation_names
      render json: result, status: :created
      return
    end

    render json: ticket, status: :created
  end

  # PUT /api/v1/tickets/1
  def update

    # permission check
    ticket = Ticket.find(params[:id])
    return if !ticket_permission(ticket)

    clean_params = Ticket.param_association_lookup(params)
    clean_params = Ticket.param_cleanup(clean_params, true)

    if ticket.update_attributes(clean_params)

      if params[:article]
        article_create(ticket, params[:article])
      end

      if params[:expand]
        result = ticket.attributes_with_relation_names
        render json: result, status: :ok
        return
      end

      render json: ticket, status: :ok
    else
      render json: ticket.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/tickets/1
  def destroy

    # permission check
    ticket = Ticket.find(params[:id])
    return if !ticket_permission(ticket)

    ticket.destroy

    head :ok
  end

  # GET /api/v1/ticket_customer
  # GET /api/v1/tickets_customer
  def ticket_customer

    # return result
    result = Ticket::ScreenOptions.list_by_customer(
      customer_id: params[:customer_id],
      limit: 15,
    )
    render json: result
  end

  # GET /api/v1/ticket_history/1
  def ticket_history

    # get ticket data
    ticket = Ticket.find(params[:id])

    # permission check
    return if !ticket_permission(ticket)

    # get history of ticket
    history = ticket.history_get(true)

    # return result
    render json: history
  end

  # GET /api/v1/ticket_related/1
  def ticket_related

    ticket = Ticket.find(params[:ticket_id])
    assets = ticket.assets({})

    # open tickets by customer
    access_condition = Ticket.access_condition(current_user)

    ticket_lists = Ticket
                   .where(
                     customer_id: ticket.customer_id,
                     state_id: Ticket::State.by_category('open')
                   )
                   .where(access_condition)
                   .where('id != ?', [ ticket.id ])
                   .order('created_at DESC')
                   .limit(6)

    # get related assets
    ticket_ids_by_customer = []
    ticket_lists.each {|ticket_list|
      ticket_ids_by_customer.push ticket_list.id
      assets = ticket_list.assets(assets)
    }

    ticket_ids_recent_viewed = []
    recent_views = RecentView.list(current_user, 8, 'Ticket')
    recent_views.each {|recent_view|
      next if recent_view['object'] != 'Ticket'
      ticket_ids_recent_viewed.push recent_view['o_id']
      recent_view_ticket = Ticket.find(recent_view['o_id'])
      assets             = recent_view_ticket.assets(assets)
    }

    # return result
    render json: {
      assets: assets,
      ticket_ids_by_customer: ticket_ids_by_customer,
      ticket_ids_recent_viewed: ticket_ids_recent_viewed,
    }
  end

  # GET /api/v1/ticket_merge/1/1
  def ticket_merge

    # check master ticket
    ticket_master = Ticket.find_by(number: params[:master_ticket_number])
    if !ticket_master
      render json: {
        result: 'faild',
        message: 'No such master ticket number!',
      }
      return
    end

    # permission check
    return if !ticket_permission(ticket_master)

    # check slave ticket
    ticket_slave = Ticket.find_by(id: params[:slave_ticket_id])
    if !ticket_slave
      render json: {
        result: 'faild',
        message: 'No such slave ticket!',
      }
      return
    end

    # permission check
    return if !ticket_permission(ticket_slave)

    # check diffetent ticket ids
    if ticket_slave.id == ticket_master.id
      render json: {
        result: 'faild',
        message: 'Can\'t merge ticket with it self!',
      }
      return
    end

    # merge ticket
    ticket_slave.merge_to(
      ticket_id: ticket_master.id,
      created_by_id: current_user.id,
    )

    # return result
    render json: {
      result: 'success',
      master_ticket: ticket_master.attributes,
      slave_ticket: ticket_slave.attributes,
    }
  end

  # GET /api/v1/ticket_split
  def ticket_split

    # permission check
    ticket = Ticket.find(params[:ticket_id])
    return if !ticket_permission(ticket)
    assets = ticket.assets({})

    # get related articles
    article = Ticket::Article.find(params[:article_id])
    assets = article.assets(assets)

    render json: {
      assets: assets
    }
  end

  # GET /api/v1/ticket_create
  def ticket_create

    # get attributes to update
    attributes_to_change = Ticket::ScreenOptions.attributes_to_change(
      user: current_user,
    )
    render json: attributes_to_change
  end

  # GET /api/v1/tickets/search
  def search

    # permit nested conditions
    params.require(:condition).permit!

    # build result list
    tickets = Ticket.search(
      limit: params[:limit],
      query: params[:term],
      condition: params[:condition],
      current_user: current_user,
    )

    if params[:expand]
      list = []
      tickets.each {|ticket|
        list.push ticket.attributes_with_relation_names
      }
      render json: list, status: :ok
      return
    end

    assets = {}
    ticket_result = []
    tickets.each do |ticket|
      ticket_result.push ticket.id
      assets = ticket.assets(assets)
    end

    # return result
    render json: {
      tickets: ticket_result,
      tickets_count: tickets.count,
      assets: assets,
    }
  end

  # GET /api/v1/tickets/selector
  def selector
    return if deny_if_not_role(Z_ROLENAME_ADMIN)

    ticket_count, tickets = Ticket.selectors(params[:condition], 6)

    assets = {}
    ticket_ids = []
    if tickets
      tickets.each do |ticket|
        ticket_ids.push ticket.id
        assets = ticket.assets(assets)
      end
    end

    # return result
    render json: {
      ticket_ids: ticket_ids,
      ticket_count: ticket_count || 0,
      assets: assets,
    }
  end

  # GET /api/v1/ticket_stats
  def stats

    if !params[:user_id] && !params[:organization_id]
      raise 'Need user_id or organization_id as param'
    end

    # permission check
    #return if !ticket_permission(ticket)

    # lookup open user tickets
    limit                      = 100
    assets                     = {}
    access_condition           = Ticket.access_condition(current_user)
    now                        = Time.zone.now
    user_tickets_open_ids      = []
    user_tickets_closed_ids    = []
    user_ticket_volume_by_year = []
    if params[:user_id]
      user = User.lookup(id: params[:user_id])
      condition = {
        'ticket.state_id' => {
          operator: 'is',
          value: Ticket::State.by_category('open').map(&:id),
        },
        'ticket.customer_id' => {
          operator: 'is',
          value: user.id,
        },
      }
      user_tickets_open = Ticket.search(
        limit: limit,
        condition: condition,
        current_user: current_user,
      )
      user_tickets_open_ids = assets_of_tickets(user_tickets_open, assets)

      # lookup closed user tickets
      condition = {
        'ticket.state_id' => {
          operator: 'is',
          value: Ticket::State.by_category('closed').map(&:id),
        },
        'ticket.customer_id' => {
          operator: 'is',
          value: user.id,
        },
      }
      user_tickets_closed = Ticket.search(
        limit: limit,
        condition: condition,
        current_user: current_user,
      )
      user_tickets_closed_ids = assets_of_tickets(user_tickets_closed, assets)

      # generate stats by user
      (0..11).each {|month_back|
        date_to_check = now - month_back.month
        date_start = "#{date_to_check.year}-#{date_to_check.month}-01 00:00:00"
        date_end   = "#{date_to_check.year}-#{date_to_check.month}-#{date_to_check.end_of_month.day} 00:00:00"

        condition = {
          'tickets.customer_id' => user.id,
        }

        # created
        created = Ticket.where('created_at > ? AND created_at < ?', date_start, date_end )
                        .where(access_condition)
                        .where(condition)
                        .count

        # closed
        closed = Ticket.where('close_time > ? AND close_time < ?', date_start, date_end  )
                       .where(access_condition)
                       .where(condition)
                       .count

        data = {
          month: date_to_check.month,
          year: date_to_check.year,
          text: Date::MONTHNAMES[date_to_check.month],
          created: created,
          closed: closed,
        }
        user_ticket_volume_by_year.push data
      }
    end

    # lookup open org tickets
    org_tickets_open_ids      = []
    org_tickets_closed_ids    = []
    org_ticket_volume_by_year = []
    if params[:organization_id] && !params[:organization_id].empty?

      condition = {
        'ticket.state_id' => {
          operator: 'is',
          value: Ticket::State.by_category('open').map(&:id),
        },
        'ticket.organization_id' => {
          operator: 'is',
          value: params[:organization_id],
        },
      }
      org_tickets_open = Ticket.search(
        limit: limit,
        condition: condition,
        current_user: current_user,
      )
      org_tickets_open_ids = assets_of_tickets(org_tickets_open, assets)

      # lookup closed org tickets
      condition = {
        'ticket.state_id' => {
          operator: 'is',
          value: Ticket::State.by_category('closed').map(&:id),
        },
        'ticket.organization_id' => {
          operator: 'is',
          value: params[:organization_id],
        },
      }
      org_tickets_closed = Ticket.search(
        limit: limit,
        condition: condition,
        current_user: current_user,
      )
      org_tickets_closed_ids = assets_of_tickets(org_tickets_closed, assets)

      # generate stats by org
      (0..11).each {|month_back|
        date_to_check = now - month_back.month
        date_start = "#{date_to_check.year}-#{date_to_check.month}-01 00:00:00"
        date_end   = "#{date_to_check.year}-#{date_to_check.month}-#{date_to_check.end_of_month.day} 00:00:00"

        condition = {
          'tickets.organization_id' => params[:organization_id],
        }

        # created
        created = Ticket.where('created_at > ? AND created_at < ?', date_start, date_end ).where(condition).count

        # closed
        closed = Ticket.where('close_time > ? AND close_time < ?', date_start, date_end  ).where(condition).count

        data = {
          month: date_to_check.month,
          year: date_to_check.year,
          text: Date::MONTHNAMES[date_to_check.month],
          created: created,
          closed: closed,
        }
        org_ticket_volume_by_year.push data
      }
    end

    # return result
    render json: {
      user_tickets_open_ids: user_tickets_open_ids,
      user_tickets_closed_ids: user_tickets_closed_ids,
      org_tickets_open_ids: org_tickets_open_ids,
      org_tickets_closed_ids: org_tickets_closed_ids,
      user_ticket_volume_by_year: user_ticket_volume_by_year,
      org_ticket_volume_by_year: org_ticket_volume_by_year,
      assets: assets,
    }
  end

  private

  def assets_of_tickets(tickets, assets)
    ticket_ids = []
    tickets.each do |ticket|
      ticket_ids.push ticket.id
      assets = ticket.assets(assets)
    end
    ticket_ids
  end

  def article_create(ticket, params)

    # create article if given
    form_id = params[:form_id]
    params.delete(:form_id)

    clean_params = Ticket::Article.param_association_lookup(params)
    clean_params = Ticket::Article.param_cleanup(clean_params, true)
    article = Ticket::Article.new(clean_params)
    article.ticket_id = ticket.id

    # store dataurl images to store
    if form_id && article.body && article.content_type =~ %r{text/html}i
      article.body.gsub!( %r{(<img\s.+?src=")(data:image/(jpeg|png);base64,.+?)">}i ) { |_item|
        file_attributes = StaticAssets.data_url_attributes($2)
        cid = "#{ticket.id}.#{form_id}.#{rand(999_999)}@#{Setting.get('fqdn')}"
        headers_store = {
          'Content-Type' => file_attributes[:mime_type],
          'Mime-Type' => file_attributes[:mime_type],
          'Content-ID' => cid,
          'Content-Disposition' => 'inline',
        }
        store = Store.add(
          object: 'UploadCache',
          o_id: form_id,
          data: file_attributes[:content],
          filename: cid,
          preferences: headers_store
        )
        "#{$1}cid:#{cid}\">"
      }
    end

    # find attachments in upload cache
    if form_id
      article.attachments = Store.list(
        object: 'UploadCache',
        o_id: form_id,
      )
    end
    if !article.save
      render json: article.errors, status: :unprocessable_entity
      return
    end

    # remove attachments from upload cache
    return if !form_id

    Store.remove(
      object: 'UploadCache',
      o_id: form_id,
    )
  end

  def ticket_all(ticket)

    # get attributes to update
    attributes_to_change = Ticket::ScreenOptions.attributes_to_change(user: current_user, ticket: ticket)

    # get related users
    assets = attributes_to_change[:assets]
    assets = ticket.assets(assets)

    # get related articles
    articles = Ticket::Article.where(ticket_id: ticket.id).order('created_at ASC, id ASC')

    # get related users
    article_ids = []
    articles.each {|article|

      # ignore internal article if customer is requesting
      next if article.internal == true && role?(Z_ROLENAME_CUSTOMER)

      # load article ids
      article_ids.push article.id

      # load assets
      assets = article.assets(assets)
    }

    # get links
    links = Link.list(
      link_object: 'Ticket',
      link_object_value: ticket.id,
    )
    link_list = []
    links.each { |item|
      link_list.push item
      if item['link_object'] == 'Ticket'
        linked_ticket = Ticket.lookup(id: item['link_object_value'])
        assets = linked_ticket.assets(assets)
      end
    }

    # get tags
    tags = Tag.tag_list(
      object: 'Ticket',
      o_id: ticket.id,
    )

    # return result
    {
      ticket_id: ticket.id,
      ticket_article_ids: article_ids,
      assets: assets,
      links: link_list,
      tags: tags,
      form_meta: attributes_to_change[:form_meta],
    }
  end

end
