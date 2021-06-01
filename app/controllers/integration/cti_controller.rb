# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Integration::CtiController < ApplicationController
  skip_before_action :verify_csrf_token
  before_action :check_configured, :check_token

  # notify about inbound call / block inbound call
  def event
    local_params = ActiveSupport::HashWithIndifferentAccess.new(params.permit!.to_h)

    cti = Cti::Driver::Cti.new(params: local_params, config: config_integration)

    result = cti.process

    # check if inbound call should get rejected
    if result[:action] == 'reject'
      response_ok(action: 'reject', reason: 'busy')
      return true
    end

    # check if outbound call changes the outbound caller_id
    if result[:action] == 'set_caller_id'
      data = {
        action:    'dial',
        caller_id: result[:params][:from_caller_id],
        number:    result[:params][:to_caller_id],
      }
      response_ok(data)
      return true
    end

    if result[:action] == 'invalid_direction'
      response_error('Invalid direction!')
      return true
    end

    response_ok({})
  end

  private

  def check_token
    if Setting.get('cti_token') != params[:token]
      response_unauthorized('Invalid token, please contact your admin!')
      return
    end

    true
  end

  def check_configured
    http_log_config facility: 'cti'

    if !Setting.get('cti_integration')
      response_error('Feature is disable, please contact your admin to enable it!')
      return
    end
    if config_integration.blank? || config_integration[:inbound].blank? || config_integration[:outbound].blank?
      response_error('Feature not configured, please contact your admin!')
      return
    end

    true
  end

  def config_integration
    @config_integration ||= Setting.get('cti_config')
  end

  def response_error(error)
    render json: { error: error }, status: :unprocessable_entity
  end

  def response_unauthorized(error)
    render json: { error: error }, status: :unauthorized
  end

  def response_ok(data)
    render json: data, status: :ok
  end

end
