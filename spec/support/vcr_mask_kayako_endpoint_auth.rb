# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

VCR.configure do |c|
  # The API key is used only inside the base64 encoded Basic Auth string, so mask that as well.
  c.filter_sensitive_data('<IMPORT_KAYAKO_ENDPOINT_BASIC_AUTH>') { Base64.encode64("#{ENV['IMPORT_KAYAKO_ENDPOINT_USERNAME']}:#{ENV['IMPORT_KAYAKO_ENDPOINT_PASSWORD']}").lines(chomp: true).join }

  # The hostname of the Kayako endpoint URL used as well
  if ENV['IMPORT_KAYAKO_ENDPOINT'].present?
    c.filter_sensitive_data('<IMPORT_KAYAKO_ENDPOINT_HOSTNAME>') { URI.parse(ENV['IMPORT_KAYAKO_ENDPOINT']).hostname }
  end
end
