# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class SearchController < ApplicationController
  prepend_before_action :authentication_check

  # GET|POST /api/v1/search
  # GET|POST /api/v1/search/:objects

  def search_generic
    # get params
    query = params[:query]
    if query.respond_to?(:permit!)
      query = query.permit!.to_h
    end
    limit = params[:limit] || 10

    # convert objects string into array of class names
    # e.g. user-ticket-another_object = %w( User Ticket AnotherObject )
    objects = if params[:objects]
                params[:objects].split('-').map(&:camelize)
              else
                Setting.get('models_searchable')
              end

    assets = {}
    result = []
    Service::Search.new(current_user: current_user).execute(
      term:    query,
      objects: objects.map(&:constantize),
      options: { limit: limit, ids: params[:ids] },
    ).each do |item|
      assets = item.assets(assets)
      result << {
        type: item.class.to_app_model.to_s,
        id:   item[:id],
      }
    end

    render json: {
      assets: assets,
      result: result,
    }
  end
end
