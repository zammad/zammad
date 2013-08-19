# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

class SearchController < ApplicationController
  before_filter :authentication_check

  # GET /api/v1/search
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
      assets = ticket.assets(assets)
      ticket_result.push ticket.id
    end

    # do query
    users = User.search(
      :query        => params[:term],
      :limit        => params[:limit],
      :current_user => current_user,
    )
    user_result = []
    users.each do |user|
      user_result.push user.id
      assets = user.assets(assets)
    end

    organizations = Organization.search(
      :query        => params[:term],
      :limit        => params[:limit],
      :current_user => current_user,
    )

    organization_result = []
    organizations.each do |organization|
      organization_result.push organization.id
      assets = organization.assets(assets)
    end

    result = []
    if ticket_result[0]
      data = {
        :name => 'Ticket',
        :ids  => ticket_result,
      }
      result.push data
    end
    if user_result[0]
      data = {
        :name => 'User',
        :ids  => user_result,
      }
      result.push data
    end
    if organization_result[0]
      data = {
        :name => 'Organization',
        :ids  => organization_result,
      }
      result.push data
    end

    # return result
    render :json => {
      :assets => assets,
      :result => result,
    }
  end

end
