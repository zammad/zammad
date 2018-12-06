# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
require 'builder'

class Integration::PlacetelController < ApplicationController
  skip_before_action :verify_csrf_token
  before_action :check_configured, :check_token

  # notify about inbound call / block inbound call
  def event

    local_params = ActiveSupport::HashWithIndifferentAccess.new(params.permit!.to_h)

    # do placetel event mapping
    if local_params['event'] == 'IncomingCall'
      local_params['direction'] = 'in'
      local_params['event'] = 'newCall'
    elsif local_params['event'] == 'HungUp'
      local_params['event'] = 'hangup'
    elsif local_params['event'] == 'CallAccepted'
      local_params['event'] = 'answer'
    end

    if local_params['user'].blank? && local_params['peer']
      local_params['user'] = get_voip_user_by_peer(local_params['peer'])
    end

    if local_params['direction'].blank?
      entry = Cti::Log.find_by(call_id: params[:call_id])
      if entry
        local_params['direction'] = entry.direction
      end
    end

    if local_params['type'] == 'missed'
      local_params['cause'] = 'cancel'
    elsif local_params['type'] == 'voicemail'
      local_params['cause'] = 'voicemail'
    elsif local_params['type'] == 'blocked'
      local_params['cause'] = 'blocked'
    elsif local_params['type'] == 'accepted'
      local_params['cause'] = 'normalClearing'
    end

    if local_params['direction'] == 'in'
      if local_params['event'] == 'newCall'
        config_inbound = config_integration[:inbound] || {}
        block_caller_ids = config_inbound[:block_caller_ids] || []

        # check if call need to be blocked
        block_caller_ids.each do |item|
          next unless item[:caller_id] == local_params['from']

          xml = Builder::XmlMarkup.new(indent: 2)
          xml.instruct!
          content = xml.Response() do
            xml.Reject('reason' => 'busy')
          end
          send_data content, type: 'application/xml; charset=UTF-8;'

          #local_params['Reject'] = 'busy'
          local_params['comment'] = 'reject, busy'
          if local_params['user']
            local_params['comment'] = "#{local_params['user']} -> reject, busy"
          end
          Cti::Log.process(local_params)
          return true
        end
      end

      Cti::Log.process(local_params)

      xml = Builder::XmlMarkup.new(indent: 2)
      xml.instruct!
      content = xml.Response()
      send_data content, type: 'application/xml; charset=UTF-8;'
      return true
    elsif local_params['direction'] == 'out'
      config_outbound = config_integration[:outbound]
      routing_table = nil
      default_caller_id = nil
      if config_outbound.present?
        routing_table = config_outbound[:routing_table]
        default_caller_id = config_outbound[:default_caller_id]
      end

      xml = Builder::XmlMarkup.new(indent: 2)
      xml.instruct!

      # set callerId
      content = nil
      to      = local_params[:to]
      from    = nil
      if to && routing_table.present?
        routing_table.each do |row|
          dest = row[:dest].gsub(/\*/, '.+?')
          next if to !~ /^#{dest}$/

          from = row[:caller_id]
          content = xml.Response() do
            xml.Dial(callerId: from) { xml.Number(params[:to]) }
          end
          break
        end
        if !content && default_caller_id.present?
          from = default_caller_id
          content = xml.Response() do
            xml.Dial(callerId: default_caller_id) { xml.Number(params[:to]) }
          end
        end
      else
        content = xml.Response()
      end
      send_data(content, type: 'application/xml; charset=UTF-8;')

      if from.present?
        local_params['from'] = from
      end
      Cti::Log.process(local_params)
      return true
    end
    response_error('Invalid direction!')
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

  def get_voip_user_by_peer(peer)
    load_voip_users[peer]
  end

  def load_voip_users
    return {} if config_integration.blank? || config_integration[:api_token].blank?

    list = Cache.get('placetelGetVoipUsers')
    return list if list

    response = UserAgent.post(
      'https://api.placetel.de/api/getVoIPUsers.json',
      {
        api_key: config_integration[:api_token],
      },
      {
        log: {
          facility: 'placetel',
        },
        json: true,
        open_timeout: 4,
        read_timeout: 6,
        total_timeout: 6,
      },
    )
    if !response.success?
      logger.error "Can't fetch getVoipUsers from '#{url}', http code: #{response.code}"
      Cache.write('placetelGetVoipUsers', {}, { expires_in: 1.hour })
      return {}
    end
    result = response.data
    if result.blank?
      logger.error "Can't fetch getVoipUsers from '#{url}', result: #{response.inspect}"
      Cache.write('placetelGetVoipUsers', {}, { expires_in: 1.hour })
      return {}
    end
    if result.is_a?(Hash) && (result['result'] == '-1' || result['result_code'] == 'error')
      logger.error "Can't fetch getVoipUsers from '#{url}', result: #{result.inspect}"
      Cache.write('placetelGetVoipUsers', {}, { expires_in: 1.hour })
      return {}
    end
    if !result.is_a?(Array)
      logger.error "Can't fetch getVoipUsers from '#{url}', result: #{result.inspect}"
      Cache.write('placetelGetVoipUsers', {}, { expires_in: 1.hour })
      return {}
    end

    list = {}
    result.each do |entry|
      next if entry['name'].blank?

      if entry['uid'].present?
        list[entry['uid']] = entry['name']
      end
      next if entry['uid2'].blank?

      list[entry['uid2']] = entry['name']
    end
    Cache.write('placetelGetVoipUsers', list, { expires_in: 24.hours })
    list
  end
end
