# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

VCR.configure do |c|
  # The API key is used only inside the base64 encoded Basic Auth string, so mask that as well.
  c.filter_sensitive_data('<IMPORT_ZENDESK_ENDPOINT_BASIC_AUTH>') { Base64.encode64("#{ENV['IMPORT_ZENDESK_ENDPOINT_USERNAME']}/token:#{ENV['IMPORT_ZENDESK_ENDPOINT_KEY']}").lines(chomp: true).join }

  # The hostname of the Zendesk endpoint URL used as well
  if ENV['IMPORT_ZENDESK_ENDPOINT'].present?
    c.filter_sensitive_data('<IMPORT_ZENDESK_ENDPOINT_HOSTNAME>') { URI.parse(ENV['IMPORT_ZENDESK_ENDPOINT']).hostname }
  end
end
