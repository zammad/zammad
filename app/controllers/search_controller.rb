# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class SearchController < ApplicationController
  before_action :authentication_check

  # GET|POST /api/v1/search/:objects

  def search_generic

    # enable search only for agents and admins
    if !current_user.role?(Z_ROLENAME_AGENT) && !current_user.role?(Z_ROLENAME_ADMIN)
      response_access_deny
      return true
    end

    # get params
    query = params[:query]
    limit = params[:limit] || 10

    # convert objects string into array of class names
    # e.g. user-ticket-another_object = %w( User Ticket AnotherObject )
    objects = params[:objects].split('-').map(&:camelize)
    search_tickets = objects.delete('Ticket')

    # try search index backend
    assets = {}
    result = []
    if SearchIndexBackend.enabled?
      items = SearchIndexBackend.search( query, limit, objects )
      items.each { |item|
        require item[:type].to_filename
        record = Kernel.const_get( item[:type] ).find( item[:id] )
        assets = record.assets(assets)
        result.push item
      }

      # do ticket query by Ticket class to handle ticket permissions
      if search_tickets
        tickets = Ticket.search(
          query: query,
          limit: limit,
          current_user: current_user,
        )
        tickets.each do |ticket|
          assets = ticket.assets(assets)
          item = {
            id: ticket.id,
            type: 'Ticket',
          }
          result.push item
        end
      end
    else

      # do query
      objects.each { |object|

        found_objects = object.constantize.search(
          query:        query,
          limit:        limit,
          current_user: current_user,
        )

        found_objects.each do |found_object|
          item = {
            id:   found_object.id,
            type: found_object.class.to_s
          }
          result.push item
          assets = found_object.assets(assets)
        end
      }
    end

    render json: {
      assets: assets,
      result: result,
    }
  end

  # GET /api/v1/search
  def search

    # get params
    query = params[:term]
    limit = params[:limit] || 10

    assets  = {}
    result  = []
    search_index_objects = %w( User Organization )
    if SearchIndexBackend.enabled?

      # to query search index backend (excluse tickets here, see below)
      found_objects = {}
      items = SearchIndexBackend.search( query, limit, search_index_objects )
      items.each { |item|
        require item[:type].to_filename
        record = Kernel.const_get( item[:type] ).find( item[:id] )
        assets = record.assets(assets)

        found_objects[ item[:type] ] ||= []
        found_objects[ item[:type] ].push item[:id]
      }

      # do ticket query by Ticket class to handle ticket permissions
      tickets = Ticket.search(
        query: query,
        limit: limit,
        current_user: current_user,
      )
      tickets.each do |ticket|
        found_objects[ 'Ticket' ] ||= []
        found_objects[ 'Ticket' ].push ticket.id
      end

      # generate whole result
      found_objects.each { |object, object_ids|

        data = {
          name: object,
          ids:  object_ids,
        }
        result.push data
      }
    else

      objects.each { |object|

        found_objects = object.constantize.search(
          query:        query,
          limit:        limit,
          current_user: current_user,
        )

        object_ids = []
        found_objects.each do |found_object|
          object_ids.push found_object.id
          assets = found_object.assets(assets)
        end

        next if object_ids.empty?

        data = {
          name: object,
          ids:  object_ids,
        }
        result.push data
      }
    end

    # return result
    render json: {
      assets: assets,
      result: result,
    }
  end

end
