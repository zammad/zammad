# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class SearchController < ApplicationController
  prepend_before_action :authentication_check

  # GET|POST /api/v1/search
  # GET|POST /api/v1/search/:objects

  def search_generic
    assets = search_result
      .result
      .values
      .each_with_object({}) { |index_result, memo| ApplicationModel::CanAssets.reduce index_result[:objects], memo }

    result = if param_by_object?
               result_by_object
             else
               result_flattened
             end

    render json: {
      assets: assets,
      result: result,
    }
  end

  private

  def result_by_object
    search_result
      .result
      .each_with_object({}) do |(model, metadata), memo|
        memo[model.to_app_model.to_s] = {
          object_ids:  metadata[:objects].pluck(:id),
          total_count: metadata[:total_count]
        }
      end
  end

  def result_flattened
    search_result
      .flattened
      .map do |item|
        {
          type: item.class.to_app_model.to_s,
          id:   item[:id],
        }
      end
  end

  def search_result
    @search_result ||= begin
      # get params
      query = params[:query].try(:permit!)&.to_h || params[:query]

      Service::Search
        .new(current_user:, query:, objects: search_result_objects, options: search_result_options)
        .execute
    end
  end

  def search_result_options
    {
      limit:            params[:limit] || 10,
      ids:              params[:ids],
      offset:           params[:offset],
      sort_by:          Array(params[:sort_by]).compact_blank.presence,
      order_by:         Array(params[:order_by]).compact_blank.presence,
      with_total_count: param_by_object?,
    }.compact
  end

  def param_by_object?
    @param_by_object ||= ActiveModel::Type::Boolean.new.cast(params[:by_object])
  end

  def search_result_objects
    objects = Models.searchable

    return objects if params[:objects].blank?

    given_objects = params[:objects].split('-').map(&:downcase)

    objects.select { |elem| given_objects.include? elem.to_app_model.to_s.downcase }
  end
end
