module Import
  module Zendesk
    module Helper
      # rubocop:disable Style/ModuleFunction
      extend self

      private

      def get_fields(zendesk_fields)
        return {} if !zendesk_fields
        fields = {}
        zendesk_fields.each { |key, value|
          fields[key] = value
        }
        fields
      end
    end
  end
end
