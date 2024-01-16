# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module UriHelper
  def self.validate_uri(string)
    uri = URI(string)

    return if %w[http https].exclude?(uri.scheme) || uri.host.blank?

    defaults = [['http', 80], ['https', 443]]
    actual   = [uri.scheme, uri.port]

    fqdn = if defaults.include? actual
             uri.host
           else
             "#{uri.host}:#{uri.port}"
           end

    { scheme: uri.scheme, fqdn: fqdn }
  rescue
    nil
  end
end
