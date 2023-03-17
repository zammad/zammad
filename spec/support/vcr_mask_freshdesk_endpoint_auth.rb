# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

# The API key is used only inside the base64 encoded Basic Auth string, so mask that as well.
VCR.configure do |c|
  c.filter_sensitive_data('<IMPORT_FRESHDESK_ENDPOINT_BASIC_AUTH>') { Base64.encode64("#{ENV['IMPORT_FRESHDESK_ENDPOINT_KEY']}:X").chomp }
end
