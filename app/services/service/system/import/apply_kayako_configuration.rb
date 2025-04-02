# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::System::Import::ApplyKayakoConfiguration < Service::System::Import::ApplyConfigurationBase

  def execute
    super

    Setting.set('import_kayako_endpoint', @endpoint)
    Setting.set('import_kayako_endpoint_username', @username)
    Setting.set('import_kayako_endpoint_password', @secret)
    Setting.set('import_backend', 'kayako')
  end

  private

  def build_endpoint
    "#{@url}/api/v1".gsub(%r{([^:])//+}, '\\1/')
  end

  def reachable!
    response = request("#{@endpoint}/teams", verify_ssl: @tls_verify)
    return if response.header&.fetch('x-api-version', nil).present?

    message = response.error.to_s.presence || __('The hostname could not be found.')
    raise_unreachable_error(message) if !response.success?
  end

  def accessible!
    result = check_accessibility { Sequencer.process('Import::Kayako::ConnectionTest') }
    raise InaccessibleError, __('The provided credentials are invalid.') if !result[:connected]
  end

  def check_accessibility(&)
    Setting.set('import_kayako_endpoint', @endpoint)
    Setting.set('import_kayako_endpoint_username', @username)
    Setting.set('import_kayako_endpoint_password', @secret)
    result = yield
    Setting.set('import_kayako_endpoint', nil)
    Setting.set('import_kayako_endpoint_username', nil)
    Setting.set('import_kayako_endpoint_password', nil)

    result
  end

  def raise_unreachable_error(message)
    messages = {
      'No such file'                                              => __('The hostname could not be found.'),
      'getaddrinfo: nodename nor servname provided, or not known' => __('The hostname could not be found.'),
      '503 Service Temporarily Unavailable'                       => __('The hostname could not be found.'),
      'No route to host'                                          => __('There is no route to this host.'),
      'Connection refused'                                        => __('The connection was refused.'),
    }

    human_message = messages.find { |key, _| message.match?(%r{#{Regexp.escape(key)}}i) }&.last

    raise UnreachableError, human_message.presence || message
  end
end
