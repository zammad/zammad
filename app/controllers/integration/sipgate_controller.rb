# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

require 'builder'

class Integration::SipgateController < ApplicationController

  # list current caller log
  def index
    return if !authentication_check
    return if deny_if_not_role('CTI')
    list = Cti::Log.order('created_at DESC').limit(60)
    render json: list
  end

  # notify about inbound call / block inbound call
  def in
    http_log_config facility: 'sipgate.io'
    return if !configured?

    if params['event'] == 'newCall'

      config = Setting.get('sipgate_config')
      config_inbound = config[:inbound] || {}
      block_caller_ids = config_inbound[:block_caller_ids] || []

      # check if call need to be blocked
      block_caller_ids.each {|item|
        next unless item[:caller_id] == params['from']
        xml = Builder::XmlMarkup.new(indent: 2)
        xml.instruct!
        content = xml.Response(onHangup: url, onAnswer: url) do
          xml.Reject('reason' => 'busy')
        end

        send_data content, type: 'application/xml; charset=UTF-8;'

        #params['Reject'] = 'busy'
        params['comment'] = 'reject, busy'
        if params['user']
          params['comment'] = "#{params['user']} -> reject, busy"
        end
        update_log(params)
        return true
      }
    end

    update_log(params)

    xml = Builder::XmlMarkup.new(indent: 2)
    xml.instruct!
    content = xml.Response(onHangup: url, onAnswer: url)
    send_data content, type: 'application/xml; charset=UTF-8;'
  end

  # set caller id of outbound call
  def out
    http_log_config facility: 'sipgate.io'
    return if !configured?

    config = Setting.get('sipgate_config')
    config_outbound = config[:outbound][:routing_table]
    default_caller_id = config[:outbound][:default_caller_id]

    xml = Builder::XmlMarkup.new(indent: 2)
    xml.instruct!

    # set callerId
    content = nil
    to      = params[:to]
    from    = nil
    if to
      config_outbound.each {|row|
        dest = row[:dest].gsub(/\*/, '.+?')
        next if to !~ /^#{dest}$/
        from = row[:caller_id]
        content = xml.Response(onHangup: url, onAnswer: url) do
          xml.Dial(callerId: from) { xml.Number(params[:to]) }
        end
        break
      }
      if !content && default_caller_id
        from = default_caller_id
        content = xml.Response(onHangup: url, onAnswer: url) do
          xml.Dial(callerId: default_caller_id) { xml.Number(params[:to]) }
        end
      end
    else
      content = xml.Response(onHangup: url, onAnswer: url)
    end

    send_data content, type: 'application/xml; charset=UTF-8;'
    if from
      params['from'] = from
    end
    update_log(params)
  end

  private

  def configured?
    if !Setting.get('sipgate_integration')
      xml_error('Feature is disable, please contact your admin to enable it!')
      return false
    end
    config = Setting.get('sipgate_config')
    if !config || !config[:inbound] || !config[:outbound]
      xml_error('Feature not configured, please contact your admin!')
      return false
    end
    true
  end

  def update_log(params)

    user = params['user']
    if params['user'] && params['user'].class == Array
      user = params['user'].join(', ')
    end
    from_comment = nil
    to_comment = nil
    if params['direction'] == 'in'
      to_comment = user
    else
      from_comment = user
    end
    comment = nil
    if params['cause']
      comment = params['cause']
    end

    if params['event'] == 'newCall'
      Cti::Log.create(
        direction: params['direction'],
        from: params['from'],
        from_comment: from_comment,
        to: params['to'],
        to_comment: to_comment,
        call_id: params['callId'],
        comment: comment,
        state: params['event'],
      )
    elsif params['event'] == 'answer'
      log = Cti::Log.find_by(call_id: params['callId'])
      raise "No such call_id #{params['callId']}" if !log
      log.state = 'answer'
      log.comment = comment
      log.save
    elsif params['event'] == 'hangup'
      log = Cti::Log.find_by(call_id: params['callId'])
      raise "No such call_id #{params['callId']}" if !log
      log.state = 'hangup'
      log.comment = comment
      log.save
    else
      raise "Unknown event #{params['event']}"
    end

  end

  def xml_error(error)
    xml = Builder::XmlMarkup.new(indent: 2)
    xml.instruct!
    content = xml.Response() do
      xml.Error(error)
    end
    send_data content, type: 'application/xml; charset=UTF-8;', status: 422
  end

  def base_url
    http_type = Setting.get('http_type')
    fqdn      = Setting.get('fqdn')
    "#{http_type}://#{fqdn}/api/v1/sipgate"
  end

  def url
    "#{base_url}/#{params['direction']}"
  end
end
