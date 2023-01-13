# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class CalendarsController < ApplicationController
  prepend_before_action { authentication_check && authorize! }

  def init
    assets = {}
    record_ids = []
    Calendar.all.order(:name, :created_at).each do |calendar|
      record_ids.push calendar.id
      assets = calendar.assets(assets)
    end

    ical_feeds = Calendar.ical_feeds
    timezones = Calendar.timezones
    render json: { record_ids:, ical_feeds:, timezones:, assets: }, status: :ok
  end

  def index
    model_index_render(Calendar, params)
  end

  def show
    model_show_render(Calendar, params)
  end

  def create
    model_create_render(Calendar, params)
  end

  def update
    model_update_render(Calendar, params)
  end

  def destroy
    model_references_check(Calendar, params)
    model_destroy_render(Calendar, params)
  end

  def timezones
    render json: {
      timezones: Calendar.timezones
    }
  end

end
