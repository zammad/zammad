module Spec
  module Support
    module Helpers
      def generate_signature(clearbit_key, webhook_body)
        'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), clearbit_key, webhook_body)
      end
    end
  end
end
