require 'builder'

class Integration::SipgateController < ApplicationController
  before_action { http_log_config facility: 'sipgate.io' }

  # notify about inbound call / block inbound call
  def in
    return if feature_disabled

    config = Setting.get('sipgate_config')
    config_inbound = config[:inbound]
    block_caller_ids = config_inbound[:block_caller_ids]

    if params['event'] == 'newCall'

      # check if call need to be blocked
      block_caller_ids.each {|item|
        next unless item[:caller_id] == params['from']
        xml = Builder::XmlMarkup.new(indent: 2)
        xml.instruct!
        content = xml.Response('onHangup' => in_url, 'onAnswer' => in_url) do
          xml.Reject('reason' => 'busy')
        end

        send_data content, type: 'application/xml; charset=UTF-8;'

        params['Reject'] = 'busy'
        Sessions.broadcast(
          event: 'sipgate.io',
          data: params
        )
        return true
      }
    end

    xml = Builder::XmlMarkup.new(indent: 2)
    xml.instruct!
    content = xml.Response('onHangup' => in_url, 'onAnswer' => in_url)

    send_data content, type: 'application/xml; charset=UTF-8;'

    # search for caller
    Sessions.broadcast(
      event: 'sipgate.io',
      data: params
    )

  end

  # set caller id of outbound call
  def out
    return if feature_disabled

    config = Setting.get('sipgate_config')
    config_outbound = config[:outbound][:routing_table]
    default_caller_id = config[:outbound][:default_caller_id]

    xml = Builder::XmlMarkup.new(indent: 2)
    xml.instruct!

    # set callerId
    content = nil
    to      = params[:to]
    if to
      config_outbound.each {|row|
        dest = row[:dest].gsub(/\*/, '.+?')
        next if to !~ /^#{dest}$/
        content = xml.Response('onHangup' => in_url, 'onAnswer' => in_url) do
          xml.Dial(callerId: row[:caller_id]) { xml.Number(params[:to]) }
        end
        break
      }
      if !content && default_caller_id
        content = xml.Response('onHangup' => in_url, 'onAnswer' => in_url) do
          xml.Dial(callerId: default_caller_id) { xml.Number(params[:to]) }
        end
      end
    else
      content = xml.Response('onHangup' => in_url, 'onAnswer' => in_url)
    end

    send_data content,
              type: 'application/xml; charset=UTF-8;'

    # notify about outbound call
    Sessions.broadcast(
      event: 'sipgate.io:out',
      data: params
    )
  end

  private

  def feature_disabled
    if !Setting.get('sipgate_integration')
      render(
        json: {},
        status: :unauthorized
      )
      return true
    end
    false
  end

  def base_url
    http_type = Setting.get('http_type')
    fqdn      = Setting.get('fqdn')

    "#{http_type}://#{fqdn}/api/v1/sipgate"
  end

  def in_url
    "#{base_url}/in"
  end
end
