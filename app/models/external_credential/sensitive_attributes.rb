# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class ExternalCredential
  module SensitiveAttributes
    def sensitive_attributes(object_payload, _object)
      (object_payload['credentials'].try(:keys) || [])
        .grep(%r{secret|token})
        .map { |elem| "credentials.#{elem}" }
    end
  end
end
