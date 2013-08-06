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
    users_data = {}
    ticket_result = []
    tickets.each do |ticket|
      ticket_result.push ticket.id
      users_data[ ticket['owner_id'] ] = User.user_data_full( ticket['owner_id'] )
      users_data[ ticket['customer_id'] ] = User.user_data_full( ticket['customer_id'] )
      users_data[ ticket['created_by_id'] ] = User.user_data_full( ticket['created_by_id'] )
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
      users_data[ user.id ] = User.user_data_full( user.id )
    end

    organizations = Organization.search(
      :query        => params[:term],
      :limit        => params[:limit],
      :current_user => current_user,
    )

    organizations_data = {}
    organization_result = []
    organizations.each do |organization|
      organization_result.push organization.id
      organizations_data[ organization.id ] = Organization.find( organization.id ).attributes
      organizations_data[ organization.id ][:user_ids] = []
      users = User.where( :organization_id => organization.id ).limit(10)
      users.each {|user|
        users_data[ user.id ] = User.user_data_full( user.id )
        organizations_data[ organization.id ][:user_ids].push user.id
      }
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
      :load => {
        :tickets       => tickets,
        :users         => users_data,
        :organizations => organizations_data,
      },
      :result => result,
    }
  end

end
