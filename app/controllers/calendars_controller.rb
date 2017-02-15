# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class CalendarsController < ApplicationController
  prepend_before_action { authentication_check(permission: 'admin.calendar') }

  def index

    # calendars
    assets = {}
    calendar_ids = []
    Calendar.all.order(:name, :created_at).each { |calendar|
      calendar_ids.push calendar.id
      assets = calendar.assets(assets)
    }

    ical_feeds = Calendar.ical_feeds
    timezones = Calendar.timezones
    render json: {
      calendar_ids: calendar_ids,
      ical_feeds: ical_feeds,
      timezones: timezones,
      assets: assets,
    }, status: :ok
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
    model_destroy_render(Calendar, params)
  end

end
