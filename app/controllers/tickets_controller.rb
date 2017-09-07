# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class TicketsController < ApplicationController
  include CreatesTicketArticles
  include TicketStats

  prepend_before_action :authentication_check

  # GET /api/v1/tickets
  def index
    offset = 0
    per_page = 100

    if params[:page] && params[:per_page]
      offset = (params[:page].to_i - 1) * params[:per_page].to_i
      per_page = params[:per_page].to_i
    end

    if per_page > 100
      per_page = 100
    end

    access_condition = Ticket.access_condition(current_user, 'read')
    tickets = Ticket.where(access_condition).order(id: 'ASC').offset(offset).limit(per_page)

    if params[:expand]
      list = []
      tickets.each { |ticket|
        list.push ticket.attributes_with_association_names
      }
      render json: list, status: :ok
      return
    end

    if params[:full]
      assets = {}
      item_ids = []
      tickets.each { |item|
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
    ticket = Ticket.find(params[:id])
    access!(ticket, 'read')

    if params[:expand]
      result = ticket.attributes_with_association_names
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
    clean_params = Ticket.association_name_to_id_convert(params)

    # overwrite params
    if !current_user.permissions?('ticket.agent')
      [:owner, :owner_id, :customer, :customer_id, :organization, :organization_id, :preferences].each { |key|
        clean_params.delete(key)
      }
      clean_params[:customer_id] = current_user.id
    end

    # try to create customer if needed
    if clean_params[:customer_id] && clean_params[:customer_id] =~ /^guess:(.+?)$/
      email = $1
      if email !~ /@/ || email =~ /(>|<|\||\!|"|§|'|\$|%|&|\(|\)|\?|\s)/
        render json: { error: 'Invalid email of customer' }, status: :unprocessable_entity
        return
      end
      customer = User.find_by(email: email)
      if !customer
        role_ids = Role.signup_role_ids
        customer = User.create(
          firstname: '',
          lastname: '',
          email: email,
          password: '',
          active: true,
          role_ids: role_ids,
        )
      end
      clean_params[:customer_id] = customer.id
    end

    clean_params = Ticket.param_cleanup(clean_params, true)
    ticket = Ticket.new(clean_params)

    # check if article is given
    if !params[:article]
      render json: { error: 'article hash is missing' }, status: :unprocessable_entity
      return
    end

    # create ticket
    ticket.save!
    ticket.with_lock do

      # create tags if given
      if params[:tags] && !params[:tags].empty?
        tags = params[:tags].split(/,/)
        tags.each { |tag|
          ticket.tag_add(tag)
        }
      end

      # create article if given
      if params[:article]
        article_create(ticket, params[:article])
      end
    end
    # create links (e. g. in case of ticket split)
    # links: {
    #   Ticket: {
    #     parent: [ticket_id1, ticket_id2, ...]
    #     normal: [ticket_id1, ticket_id2, ...]
    #     child: [ticket_id1, ticket_id2, ...]
    #   },
    # }
    if params[:links]
      raise 'Invalid link structure' if params[:links].to_h.class != Hash
      params[:links].each { |target_object, link_types_with_object_ids|
        raise 'Invalid link structure (Object)' if link_types_with_object_ids.to_h.class != Hash
        link_types_with_object_ids.each { |link_type, object_ids|
          raise 'Invalid link structure (Object->LinkType)' if object_ids.class != Array
          object_ids.each { |local_object_id|
            link = Link.add(
              link_type: link_type,
              link_object_target: target_object,
              link_object_target_value: local_object_id,
              link_object_source: 'Ticket',
              link_object_source_value: ticket.id,
            )
          }
        }
      }
    end

    if params[:expand]
      result = ticket.reload.attributes_with_association_names
      render json: result, status: :created
      return
    end

    if params[:all]
      render json: ticket_all(ticket.reload)
      return
    end

    render json: ticket.reload, status: :created
  end

  # PUT /api/v1/tickets/1
  def update
    ticket = Ticket.find(params[:id])
    access!(ticket, 'change')

    clean_params = Ticket.association_name_to_id_convert(params)
    clean_params = Ticket.param_cleanup(clean_params, true)

    # overwrite params
    if !current_user.permissions?('ticket.agent')
      [:owner, :owner_id, :customer, :customer_id, :organization, :organization_id, :preferences].each { |key|
        clean_params.delete(key)
      }
    end

    ticket.with_lock do
      ticket.update_attributes!(clean_params)
      if params[:article]
        article_create(ticket, params[:article])
      end
    end

    if params[:expand]
      result = ticket.reload.attributes_with_association_names
      render json: result, status: :ok
      return
    end

    if params[:all]
      render json: ticket_all(ticket.reload)
      return
    end

    render json: ticket.reload, status: :ok
  end

  # DELETE /api/v1/tickets/1
  def destroy
    ticket = Ticket.find(params[:id])
    access!(ticket, 'delete')

    raise Exceptions::NotAuthorized, 'Not authorized (admin permission required)!' if !current_user.permissions?('admin')

    ticket.destroy!

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
    access!(ticket, 'read')

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
    access_condition = Ticket.access_condition(current_user, 'read')

    ticket_lists = Ticket
                   .where(
                     customer_id: ticket.customer_id,
                     state_id: Ticket::State.by_category(:open)
                   )
                   .where(access_condition)
                   .where('id != ?', [ ticket.id ])
                   .order('created_at DESC')
                   .limit(6)

    # if we do not have open related tickets, search for any tickets
    if ticket_lists.empty?
      ticket_lists = Ticket
                     .where(
                       customer_id: ticket.customer_id,
                     ).where.not(
                       state_id: Ticket::State.by_category(:merged)
                     )
                     .where(access_condition)
                     .where('id != ?', [ ticket.id ])
                     .order('created_at DESC')
                     .limit(6)
    end

    # get related assets
    ticket_ids_by_customer = []
    ticket_lists.each { |ticket_list|
      ticket_ids_by_customer.push ticket_list.id
      assets = ticket_list.assets(assets)
    }

    ticket_ids_recent_viewed = []
    recent_views = RecentView.list(current_user, 8, 'Ticket').delete_if { |object| object['o_id'] == ticket.id }
    recent_views.each { |recent_view|
      next if recent_view['object'] != 'Ticket'
      ticket_ids_recent_viewed.push recent_view['o_id']
      recent_view_ticket = Ticket.find(recent_view['o_id'])
      next if recent_view_ticket.state.state_type.name == 'merged'
      assets = recent_view_ticket.assets(assets)
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
        result: 'failed',
        message: 'No such master ticket number!',
      }
      return
    end
    access!(ticket_master, 'full')

    # check slave ticket
    ticket_slave = Ticket.find_by(id: params[:slave_ticket_id])
    if !ticket_slave
      render json: {
        result: 'failed',
        message: 'No such slave ticket!',
      }
      return
    end
    access!(ticket_slave, 'full')

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
    ticket = Ticket.find(params[:ticket_id])
    access!(ticket, 'read')
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
      current_user: current_user,
    )
    render json: attributes_to_change
  end

  # GET /api/v1/tickets/search
  def search

    # permit nested conditions
    if params[:condition]
      params.require(:condition).permit!
    end

    # set limit for pagination if needed
    if params[:page] && params[:per_page]
      params[:limit] = params[:page].to_i * params[:per_page].to_i
    end

    if params[:limit] && params[:limit].to_i > 100
      params[:limit].to_i = 100
    end

    # build result list
    tickets = Ticket.search(
      limit: params[:limit],
      query: params[:query],
      condition: params[:condition],
      current_user: current_user,
    )

    # do pagination if needed
    if params[:page] && params[:per_page]
      offset = (params[:page].to_i - 1) * params[:per_page].to_i
      tickets = tickets.slice(offset, params[:per_page].to_i) || []
    end

    if params[:expand]
      list = []
      tickets.each { |ticket|
        list.push ticket.attributes_with_association_names
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
    permission_check('admin.*')

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

    # lookup open user tickets
    limit            = 100
    assets           = {}
    access_condition = Ticket.access_condition(current_user, 'read')

    user_tickets = {}
    if params[:user_id]
      user = User.lookup(id: params[:user_id])
      if !user
        raise "No such user with id #{params[:user_id]}"
      end
      conditions = {
        closed_ids: {
          'ticket.state_id' => {
            operator: 'is',
            value: Ticket::State.by_category(:closed).pluck(:id),
          },
          'ticket.customer_id' => {
            operator: 'is',
            value: user.id,
          },
        },
        open_ids: {
          'ticket.state_id' => {
            operator: 'is',
            value: Ticket::State.by_category(:open).pluck(:id),
          },
          'ticket.customer_id' => {
            operator: 'is',
            value: user.id,
          },
        },
      }
      conditions.each { |key, local_condition|
        user_tickets[key] = ticket_ids_and_assets(local_condition, current_user, limit, assets)
      }

      # generate stats by user
      condition = {
        'tickets.customer_id' => user.id,
      }
      user_tickets[:volume_by_year] = ticket_stats_last_year(condition, access_condition)

    end

    # lookup open org tickets
    org_tickets = {}
    if params[:organization_id] && !params[:organization_id].empty?
      organization = Organization.lookup(id: params[:organization_id])
      if !organization
        raise "No such organization with id #{params[:organization_id]}"
      end
      conditions = {
        closed_ids: {
          'ticket.state_id' => {
            operator: 'is',
            value: Ticket::State.by_category(:closed).pluck(:id),
          },
          'ticket.organization_id' => {
            operator: 'is',
            value: organization.id,
          },
        },
        open_ids: {
          'ticket.state_id' => {
            operator: 'is',
            value: Ticket::State.by_category(:open).pluck(:id),
          },
          'ticket.organization_id' => {
            operator: 'is',
            value: organization.id,
          },
        },
      }
      conditions.each { |key, local_condition|
        org_tickets[key] = ticket_ids_and_assets(local_condition, current_user, limit, assets)
      }

      # generate stats by org
      condition = {
        'tickets.organization_id' => organization.id,
      }
      org_tickets[:volume_by_year] = ticket_stats_last_year(condition, access_condition)
    end

    # return result
    render json: {
      user: user_tickets,
      organization: org_tickets,
      assets: assets,
    }
  end

  private

  def ticket_all(ticket)

    # get attributes to update
    attributes_to_change = Ticket::ScreenOptions.attributes_to_change(
      current_user: current_user,
      ticket:       ticket
    )

    # get related users
    assets = attributes_to_change[:assets]
    assets = ticket.assets(assets)

    # get related users
    article_ids = []
    ticket.articles.each { |article|

      # ignore internal article if customer is requesting
      next if article.internal == true && current_user.permissions?('ticket.customer')

      article_ids.push article.id
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
    tags = ticket.tag_list

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
