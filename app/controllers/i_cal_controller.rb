# Copyright (C) 2012-2015 Zammad Foundation, http://zammad-foundation.org/

require 'icalendar'

class ICalController < ApplicationController
  before_action { authentication_check( { basic_auth_promt: true, token_action: 'iCal' } ) }

  # @path       [GET] /ical
  #
  # @summary          Returns an iCal file with all objects matching the iCal preferences of the current user as events.
  #
  # @response_message 200 [String] iCal file ready to import in calendar applications.
  # @response_message 401          Permission denied.
  def all
    ical_object = ICal.new( current_user )
    ical        = ical_object.all

    send_data(
      ical,
      filename: 'zammad.ical',
      type: 'text/plain',
      disposition: 'inline'
    )
  rescue => e
    logger.error e.message
    logger.error e.backtrace.inspect
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # @path       [GET] /ical/:object
  # @path       [GET] /ical/:object/:method
  #
  # @summary          Returns an iCal file of the given object (and method) matching the iCal preferences of the current user as events.
  #
  # @response_message 200 [String] iCal file ready to import in calendar applications.
  # @response_message 401          Permission denied.
  def object
    ical_object = ICal.new( current_user )

    # remove the last char (s/plural) from the object name
    object_name = params[:object].to_s[0...-1].to_sym

    ical = ical_object.generic( object_name, params[:method] )

    send_data(
      ical,
      filename: 'zammad.ical',
      type: 'text/plain',
      disposition: 'inline'
    )
  rescue => e
    logger.error e.message
    logger.error e.backtrace.inspect
    render json: { error: e.message }, status: :unprocessable_entity
  end

end
