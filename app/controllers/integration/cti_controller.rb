# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Integration::CtiController < ApplicationController
  skip_before_action :verify_csrf_token
  before_action :check_configured, :check_token

  # notify about inbound call / block inbound call
  def event
    if params['direction'] == 'in'
      if params['event'] == 'newCall'
        config_inbound = config_integration[:inbound] || {}
        block_caller_ids = config_inbound[:block_caller_ids] || []

        # check if call need to be blocked
        block_caller_ids.each do |item|
          next unless item[:caller_id] == params['from']

          render json: { action: 'reject', reason: 'busy' }, status: :ok

          #params['Reject'] = 'busy'
          params['comment'] = 'reject, busy'
          if params['user']
            params['comment'] = "#{params['user']} -> reject, busy"
          end
          Cti::Log.process(params)
          return true
        end
      end

      Cti::Log.process(params)

      render json: {}, status: :ok
      return true
    elsif params['direction'] == 'out'
      config_outbound = config_integration[:outbound]
      routing_table = nil
      default_caller_id = nil
      if config_outbound.present?
        routing_table = config_outbound[:routing_table]
        default_caller_id = config_outbound[:default_caller_id]
      end

      # set callerId
      data    = {}
      to      = params[:to]
      from    = nil
      if to && routing_table.present?
        routing_table.each do |row|
          dest = row[:dest].gsub(/\*/, '.+?')
          next if to !~ /^#{dest}$/
          from = row[:caller_id]
          data = {
            action: 'dial',
            caller_id: from,
            number: params[:to]
          }
          break
        end
        if data.blank? && default_caller_id.present?
          from = default_caller_id
          data = {
            action: 'dial',
            caller_id: default_caller_id,
            number: params[:to]
          }
        end
      end
      render json: data, status: :ok

      if from.present?
        params['from'] = from
      end
      Cti::Log.process(params)
      return true
    end
    render json: { error: 'Invalid direction!' }, status: :unprocessable_entity
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

end
