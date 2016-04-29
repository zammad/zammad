# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

require 'builder'

class Integration::SipgateController < ApplicationController

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
    preferences = nil
    if params['direction'] == 'in'
      to_comment = user
      from_comment, preferences = update_log_item('from')
    else
      from_comment = user
      to_comment, preferences = update_log_item('to')
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
        preferences: preferences,
      )
    elsif params['event'] == 'answer'
      log = Cti::Log.find_by(call_id: params['callId'])
      raise "No such call_id #{params['callId']}" if !log
      log.state = 'answer'
      log.start = Time.zone.now
      if user
        log.to_comment = user
      end
      log.comment = comment
      log.save
    elsif params['event'] == 'hangup'
      log = Cti::Log.find_by(call_id: params['callId'])
      raise "No such call_id #{params['callId']}" if !log
      if params['direction'] == 'in' && log.state == 'newCall'
        log.done = false
      end
      if params['direction'] == 'in' && log.to_comment == 'voicemail'
        log.done = false
      end
      log.state = 'hangup'
      log.end = Time.zone.now
      log.comment = comment
      log.save
    else
      raise "Unknown event #{params['event']}"
    end

  end

  def update_log_item(direction)
    from_comment_known = ''
    from_comment_maybe = ''
    preferences_known = {}
    preferences_known[direction] = []
    preferences_maybe = {}
    preferences_maybe[direction] = []
    caller_ids = Cti::CallerId.lookup(params[direction])
    caller_ids.each {|record|
      if record.level == 'known'
        preferences_known[direction].push record
      else
        preferences_maybe[direction].push record
      end
      comment = ''
      if record.user_id
        user = User.lookup(id: record.user_id)
        if user
          comment += user.fullname
        end
      elsif !record.comment.empty?
        comment += record.comment
      end
      if record.level == 'known'
        if !from_comment_known.empty?
          from_comment_known += ','
        end
        from_comment_known += comment
      else
        if !from_comment_maybe.empty?
          from_comment_maybe += ','
        end
        from_comment_maybe += comment
      end
    }
    return [from_comment_known, preferences_known] if !from_comment_known.empty?
    return ["maybe #{from_comment_maybe}", preferences_maybe] if !from_comment_maybe.empty?
    nil
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
