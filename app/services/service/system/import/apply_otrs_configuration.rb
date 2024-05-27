# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::System::Import::ApplyOtrsConfiguration < Service::System::Import::ApplyConfigurationBase

  def execute
    sanitize_url

    super

    parse_url

    Setting.set('import_otrs_endpoint', @endpoint)
    Setting.set('import_otrs_endpoint_key', @secret)
    Setting.set('import_backend', 'otrs')
  end

  private

  def build_endpoint
    nil
  end

  def reachable!
    response = request(@url, verify_ssl: @tls_verify)
    raise_unreachable_error(response.error) if !response.success?

    verify_migrator!(response)
  end

  def verify_migrator!(response)
    begin
      migrator = JSON.parse(response.body)
    rescue JSON::ParserError
      raise_unreachable_error
    end

    raise_unreachable_error if !migrator.is_a?(Hash)
    %w[Notice Success].each do |key|
      raise_unreachable_error if !migrator.key?(key)
    end
    raise_unreachable_error if !migrator['Notice'].start_with?('zammad migrator')

    return if migrator['Success'].positive?

    message = migrator.fetch('Error', nil)
    raise_unreachable_error(message)
  end

  def sanitize_url
    # Replace semicolons with ampersands to allow proper processing of query parameters.
    current_url = @url.to_s

    @url = Addressable::URI.parse(
      CGI.unescape(current_url).split('?').each_with_index.map { |part, i| i.positive? ? part.tr(';', '&') : part }.join('?')
    ).normalize.to_s
  end

  def parse_url
    uri = Addressable::URI.parse(@url)

    @secret = uri.query_values['Key']

    port = uri.port.presence || (uri.scheme == 'https' ? 443 : 80)
    @endpoint = "#{uri.scheme}://#{uri.host}:#{port}#{uri.path}?Action=ZammadMigrator"
  end

  def accessible!
    Setting.set('import_otrs_endpoint', @url)
    Setting.set('import_otrs_endpoint_key', @secret)
    begin
      accessible = Import::OTRS.connection_test
    rescue
      # noop
    end
    Setting.set('import_otrs_endpoint', nil)
    Setting.set('import_otrs_endpoint_key', nil)

    raise InaccessibleError, __('The OTRS migrator plugin is not accessable. Please verify the API key.') if !accessible
  end

  def raise_unreachable_error(message = nil)
    raise UnreachableError, __('Please install the OTRS migrator plugin and provide a valid URL.') if message.blank?

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
