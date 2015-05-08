# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class SearchController < ApplicationController
  before_action :authentication_check

  # GET /api/v1/search_user_org
  def search_user_org

    # enable search only for agents and admins
    if !current_user.role?(Z_ROLENAME_AGENT) && !current_user.role?(Z_ROLENAME_ADMIN)
      response_access_deny
      return true
    end

    # get params
    query = params[:query]
    limit = params[:limit] || 10

    # try search index backend
    assets = {}
    result = []
    if SearchIndexBackend.enabled?
      items = SearchIndexBackend.search( query, limit, %w(User Organization) )
      items.each { |item|
        require item[:type].to_filename
        record = Kernel.const_get( item[:type] ).find( item[:id] )
        assets = record.assets(assets)
        result.push item
      }
    else
      # do query
      users = User.search(
        query: query,
        limit: limit,
        current_user: current_user,
      )
      user_result = []
      users.each do |user|
        item = {
          id: user.id,
          type: user.class.to_s
        }
        result.push item
        assets = user.assets(assets)
      end

      organizations = Organization.search(
        query: query,
        limit: limit,
        current_user: current_user,
      )

      organization_result = []
      organizations.each do |organization|
        item = {
          id: organization.id,
          type: organization.class.to_s
        }
        result.push item
        assets = organization.assets(assets)
      end
    end

    render json: {
      assets: assets,
      result: result,
    }
  end

  # GET /api/v1/search
  def search

    # build result list
    tickets = Ticket.search(
      limit: params[:limit],
      query: params[:term],
      current_user: current_user,
    )
    assets = {}
    ticket_result = []
    tickets.each do |ticket|
      assets = ticket.assets(assets)
      ticket_result.push ticket.id
    end

    # do query
    users = User.search(
      query: params[:term],
      limit: params[:limit],
      current_user: current_user,
    )
    user_result = []
    users.each do |user|
      user_result.push user.id
      assets = user.assets(assets)
    end

    organizations = Organization.search(
      query: params[:term],
      limit: params[:limit],
      current_user: current_user,
    )

    organization_result = []
    organizations.each do |organization|
      organization_result.push organization.id
      assets = organization.assets(assets)
    end

    result = []
    if ticket_result[0]
      data = {
        name: 'Ticket',
        ids: ticket_result,
      }
      result.push data
    end
    if user_result[0]
      data = {
        name: 'User',
        ids: user_result,
      }
      result.push data
    end
    if organization_result[0]
      data = {
        name: 'Organization',
        ids: organization_result,
      }
      result.push data
    end

    # return result
    render json: {
      assets: assets,
      result: result,
    }
  end

end
