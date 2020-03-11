class Channel::Driver::Sms::Sms77
  NAME = 'sms/sms77'.freeze

  def send(options, attr, _notification = false)
    Rails.logger.info "Sending SMS to recipient #{attr[:recipient]}"

    return true if Setting.get('import_mode')

    Rails.logger.info "Backend sending sms77 SMS to #{attr[:recipient]}"

    begin
      url = build_url(options, attr)

      if Setting.get('developer_mode') != true
        response = Faraday.get(url).body
        raise response if '100' != response
      end

      true
    rescue => e
      Rails.logger.debug "sms77 error: #{e.inspect}"
      raise e
    end
  end

  def self.definition
    {
        name: 'sms77',
        adapter: 'sms/sms77',
        notification: [
            {name: 'options::api_key', display: 'API Key', tag: 'input', type: 'text', limit: 64, null: false, placeholder: 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'},
            {name: 'options::from', display: 'From', tag: 'input', type: 'text', limit: 16, null: true, placeholder: '00491710000000'},
        ]
    }
  end

  private

  def build_url(options, attr)
    params = {
        p: options[:api_key],
        text: attr[:message],
        to: attr[:recipient],
        from: options[:from],
        sendWith: 'zammad',
    }

    'https://gateway.sms77.io/api/sms?' + URI.encode_www_form(params)
  end
end
