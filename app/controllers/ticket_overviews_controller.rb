# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

require 'ticket/overviews'

class TicketOverviewsController < ApplicationController
  prepend_before_action :authentication_check

  # GET /api/v1/ticket_overviews
  def show

    # get navbar overview data
    if !params[:view]
      index_and_lists = Ticket::Overviews.index(current_user)
      indexes = []
      index_and_lists.each { |index|
        assets = {}
        overview = Overview.lookup(id: index[:overview][:id])
        meta = {
          name: overview.name,
          prio: overview.prio,
          link: overview.link,
          count: index[:count],
        }
        indexes.push meta
      }
      render json: indexes
      return
    end

    index_and_lists = Ticket::Overviews.index(current_user)

    assets = {}
    result = {}
    index_and_lists.each { |index|
      next if index[:overview][:view] != params[:view]

      overview = Overview.lookup(id: index[:overview][:id])
      assets = overview.assets(assets)
      index[:tickets].each { |ticket_meta|
        ticket = Ticket.lookup(id: ticket_meta[:id])
        assets = ticket.assets(assets)
      }
      result = index
    }

    render json: {
      assets: assets,
      index: result,
    }
  end

end
