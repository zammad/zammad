module Clearbit
  module Errors
    # Raised when the Webhook Request Signature doesn't validate.
    class InvalidWebhookSignature < StandardError
      def to_s
        'Clearbit Webhook Request Signature was invalid.'
      end
    end
  end
end
