# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'builder'

class Integration::PlacetelController < ApplicationController
  skip_before_action :verify_csrf_token
  before_action :check_configured, :check_token

  # notify about inbound call / block inbound call
  def event

    local_params = ActiveSupport::HashWithIndifferentAccess.new(params.permit!.to_h)

    cti = Cti::Driver::Placetel.new(params: local_params, config: config_integration)

    result = cti.process

    # check if inbound call should get rejected
    if result[:action] == 'reject'
      response_reject(result)
      return true
    end

    # check if outbound call changes the outbound caller_id
    if result[:action] == 'set_caller_id'
      response_set_caller_id(result)
      return true
    end

    if result[:action] == 'invalid_direction'
      response_error('Invalid direction!')
      return true
    end

    response_ok(response)
    true
  end

  private

  def check_token
    if Setting.get('placetel_token') != params[:token]
      response_unauthorized('Invalid token, please contact your admin!')
      return
    end

    true
  end

  def check_configured
    http_log_config facility: 'placetel'

    if !Setting.get('placetel_integration')
      response_error('Feature is disable, please contact your admin to enable it!')
      return
    end
    if config_integration.blank? || config_integration[:inbound].blank? || config_integration[:outbound].blank?
      response_error('Feature not configured, please contact your admin!')
      return
    end

    true
  end

  def xml_error(error, code)
    xml = Builder::XmlMarkup.new(indent: 2)
    xml.instruct!
    content = xml.Response() do
      xml.Error(error)
    end
    send_data content, type: 'application/xml; charset=UTF-8;', status: code
  end

  def config_integration
    @config_integration ||= Setting.get('placetel_config')
  end

  def response_error(error)
    xml_error(error, 422)
  end

  def response_unauthorized(error)
    xml_error(error, 401)
  end

  def response_reject(_result)
    xml = Builder::XmlMarkup.new(indent: 2)
    xml.instruct!
    content = xml.Response() do
      xml.Reject({ reason: 'busy' })
    end
    send_data content, type: 'application/xml; charset=UTF-8;'
  end

  def response_set_caller_id(result)
    xml = Builder::XmlMarkup.new(indent: 2)
    xml.instruct!
    content = xml.Response() do
      xml.Dial(callerId: result[:params][:from_caller_id]) { xml.Number(result[:params][:to_caller_id]) }
    end
    send_data(content, type: 'application/xml; charset=UTF-8;')
  end

  def response_ok(_result)
    xml = Builder::XmlMarkup.new(indent: 2)
    xml.instruct!
    content = xml.Response()
    send_data content, type: 'application/xml; charset=UTF-8;'
  end

end
