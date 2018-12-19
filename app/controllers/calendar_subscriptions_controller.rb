# Copyright (C) 2012-2015 Zammad Foundation, http://zammad-foundation.org/
class CalendarSubscriptionsController < ApplicationController
  prepend_before_action { authentication_check( { basic_auth_promt: true, permission: 'user_preferences.calendar' } ) }

  # @path       [GET] /calendar_subscriptions
  #
  # @summary          Returns an iCal file with all objects matching the calendar subscriptions preferences of the current user as events.
  #
  # @response_message 200 [String] iCal file ready to import in calendar applications.
  # @response_message 401          Permission denied.
  def all
    calendar_subscriptions = CalendarSubscriptions.new(current_user)
    ical                   = calendar_subscriptions.all

    send_data(
      ical,
      filename:    'zammad.ical',
      type:        'text/plain',
      disposition: 'inline'
    )
  rescue => e
    logger.error e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # @path       [GET] /calendar_subscriptions/:object
  # @path       [GET] /calendar_subscriptions/:object/:method
  #
  # @summary          Returns an iCal file of the given object (and method) matching the calendar subscriptions preferences of the current user as events.
  #
  # @response_message 200 [String] iCal file ready to import in calendar applications.
  # @response_message 401          Permission denied.
  def object
    calendar_subscriptions = CalendarSubscriptions.new(current_user)
    ical                   = calendar_subscriptions.generic(params[:object], params[:method])

    send_data(
      ical,
      filename:    'zammad.ical',
      type:        'text/plain',
      disposition: 'inline'
    )
  rescue => e
    logger.error e
    render json: { error: e.message }, status: :unprocessable_entity
  end

end
