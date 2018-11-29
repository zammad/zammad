module Doorkeeper
  module OAuth
    class Error < Struct.new(:name, :state)
      def description
        I18n.translate(
          name,
          scope: [:doorkeeper, :errors, :messages],
          default: :server_error
        )
      end
    end
  end
end
