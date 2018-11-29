module Doorkeeper
  module Models
    module Expirable
      # Indicates whether the object is expired (`#expires_in` present and
      # expiration time has come).
      #
      # @return [Boolean] true if object expired and false in other case
      def expired?
        expires_in && Time.now.utc > expired_time
      end

      # Calculates expiration time in seconds.
      #
      # @return [Integer, nil] number of seconds if object has expiration time
      #   or nil if object never expires.
      def expires_in_seconds
        return nil if expires_in.nil?
        expires = (created_at + expires_in.seconds) - Time.now.utc
        expires_sec = expires.seconds.round(0)
        expires_sec > 0 ? expires_sec : 0
      end

      private

      def expired_time
        created_at + expires_in.seconds
      end
    end
  end
end
