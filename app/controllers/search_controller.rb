# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class SearchController < ApplicationController
  before_action :authentication_check

  # GET|POST /api/v1/search
  # GET|POST /api/v1/search/:objects

  def search_generic

    # enable search only for users with valid session
    if !current_user
      response_access_deny
      return true
    end

    # get params
    query = params[:query]
    limit = params[:limit] || 10

    # convert objects string into array of class names
    # e.g. user-ticket-another_object = %w( User Ticket AnotherObject )
    if !params[:objects]
      objects_all = %w( Ticket User Organization )
    else
      objects_all = params[:objects].split('-').map(&:camelize)
    end
    objects = objects_all.clone
puts "OBJECTS: #{objects.inspect}"
    search_tickets = objects.delete('Ticket')
puts "OBJECTS_a: #{objects_all.inspect}/#{search_tickets.inspect}"
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
      objects_all.each { |object|

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

end
