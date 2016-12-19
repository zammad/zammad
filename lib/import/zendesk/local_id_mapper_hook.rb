module Import
  module Zendesk
    module LocalIDMapperHook

      # rubocop:disable Style/ModuleFunction
      extend self

      def local_id(zendesk_id)
        init_mapping
        @zendesk_mapping[ zendesk_id ]
      end

      def post_import_hook(_record, backend_instance)
        init_mapping
        @zendesk_mapping[ backend_instance.zendesk_id ] = backend_instance.id
      end

      private

      def init_mapping
        @zendesk_mapping ||= {}
      end
    end
  end
end
