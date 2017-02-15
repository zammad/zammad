# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

require 'builder'

class Integration::SipgateController < ApplicationController
  skip_before_action :verify_csrf_token
  before_action :check_configured

  # notify about inbound call / block inbound call
  def in
    if params['event'] == 'newCall'
      config_inbound = config[:inbound] || {}
      block_caller_ids = config_inbound[:block_caller_ids] || []

      # check if call need to be blocked
      block_caller_ids.each { |item|
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
        Cti::Log.process(params)
        return true
      }
    end

    Cti::Log.process(params)

    xml = Builder::XmlMarkup.new(indent: 2)
    xml.instruct!
    content = xml.Response(onHangup: url, onAnswer: url)
    send_data content, type: 'application/xml; charset=UTF-8;'
  end

  # set caller id of outbound call
  def out
    config_outbound = config[:outbound][:routing_table]
    default_caller_id = config[:outbound][:default_caller_id]

    xml = Builder::XmlMarkup.new(indent: 2)
    xml.instruct!

    # set callerId
    content = nil
    to      = params[:to]
    from    = nil
    if to
      config_outbound.each { |row|
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
    Cti::Log.process(params)
  end

  private

  def check_configured
    http_log_config facility: 'sipgate.io'

    if !Setting.get('sipgate_integration')
      xml_error('Feature is disable, please contact your admin to enable it!')
      return
    end
    if !config || !config[:inbound] || !config[:outbound]
      xml_error('Feature not configured, please contact your admin!')
      return
    end
  end

  def config
    @config ||= Setting.get('sipgate_config')
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
