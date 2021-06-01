# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Channel::Driver::Sms::Massenversand
  NAME = 'sms/massenversand'.freeze

  def send(options, attr, _notification = false)
    Rails.logger.info "Sending SMS to recipient #{attr[:recipient]}"

    return true if Setting.get('import_mode')

    Rails.logger.info "Backend sending Massenversand SMS to #{attr[:recipient]}"
    begin
      url = build_url(options, attr)

      if Setting.get('developer_mode') != true
        response = Faraday.get(url).body

        if !response.match?('OK')
          message = "Received non-OK response from gateway URL '#{url}'"
          Rails.logger.error "#{message}: #{response.inspect}"
          raise message
        end
      end

      true
    rescue => e
      message = "Error while performing request to gateway URL '#{url}'"
      Rails.logger.error message
      Rails.logger.error e
      raise message
    end
  end

  def self.definition
    {
      name:         'Massenversand',
      adapter:      'sms/massenversand',
      notification: [
        { name: 'options::gateway', display: 'Gateway', tag: 'input', type: 'text', limit: 200, null: false, placeholder: 'https://gate1.goyyamobile.com/sms/sendsms.asp', default: 'https://gate1.goyyamobile.com/sms/sendsms.asp' },
        { name: 'options::token', display: 'Token', tag: 'input', type: 'text', limit: 200, null: false, placeholder: 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' },
        { name: 'options::sender', display: 'Sender', tag: 'input', type: 'text', limit: 200, null: false, placeholder: '00491710000000' },
      ]
    }
  end

  private

  def build_url(options, attr)
    params = {
      authToken: options[:token],
      getID:     1,
      msg:       attr[:message],
      msgtype:   'c',
      receiver:  attr[:recipient],
      sender:    options[:sender]
    }

    "#{options[:gateway]}?#{URI.encode_www_form(params)}"
  end
end
