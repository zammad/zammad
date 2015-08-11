# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

require 'ticket/overviews'

class TicketOverviewsController < ApplicationController
  before_action :authentication_check

  # GET /api/v1/ticket_overviews
  def show

    # get navbar overview data
    if !params[:view]
      result = Ticket::Overviews.list(
        current_user: current_user,
      )
      render json: result
      return
    end

    # get real overview data
    if params[:array]
      overview = Ticket::Overviews.list(
        view: params[:view],
        current_user: current_user,
        array: true,
      )
      tickets = []
      overview[:tickets].each {|ticket_id|
        data = { id: ticket_id }
        tickets.push data
      }

      # return result
      render json: {
        overview: overview[:overview],
        tickets: tickets,
        tickets_count: overview[:tickets_count],
      }
      return
    end
    overview = Ticket::Overviews.list(
      view: params[:view],
      current_user: current_user,
      array: true,
    )
    if !overview
      render json: { error: "No such view #{params[:view]}!" }, status: :unprocessable_entity
      return
    end

    # get related users
    assets = {}
    overview[:ticket_ids].each {|ticket_id|
      ticket = Ticket.lookup( id: ticket_id )
      assets = ticket.assets(assets)
    }

    # get groups
    group_ids = []
    Group.where( active: true ).each { |group|
      group_ids.push group.id
    }
    agents = {}
    User.of_role('Agent').each { |user|
      agents[ user.id ] = 1
    }
    groups_users = {}
    group_ids.each {|group_id|
      groups_users[ group_id ] = []
      Group.find(group_id).users.each {|user|
        next if !agents[ user.id ]
        groups_users[ group_id ].push user.id
        assets = user.assets( assets )
      }
    }

    # return result
    render json: {
      view: params[:view],
      overview: overview[:overview],
      ticket_ids: overview[:ticket_ids],
      tickets_count: overview[:tickets_count],
      bulk: {
        group_id__owner_id: groups_users,
      },
      assets: assets,
    }
  end

end
