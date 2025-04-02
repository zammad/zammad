# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class ActivityStreamController < ApplicationController
  prepend_before_action :authentication_check

  # GET /api/v1/activity_stream
  def show
    activity_stream = current_user.activity_stream(params[:limit])

    if response_expand?
      list = activity_stream.map(&:attributes_with_association_names)
      render json: list, status: :ok
      return
    end

    if response_full?
      assets = {}
      item_ids = []
      activity_stream.each do |item|
        item_ids.push item.id
        assets = item.assets(assets)
      end
      render json: {
        record_ids: item_ids,
        assets:     assets,
      }, status: :ok
      return
    end

    all = activity_stream.map(&:attributes_with_association_ids)
    render json: all, status: :ok
  end
end
