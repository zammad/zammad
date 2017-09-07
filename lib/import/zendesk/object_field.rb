module Import
  module Zendesk
    class ObjectField

      attr_reader :zendesk_id, :id

      def initialize(object_field)

        import(object_field)

        @zendesk_id = object_field.id
        @id         = local_name(object_field)
      end

      private

      def local_name(object_field)
        @local_name ||= remote_name(object_field).gsub(%r{[\s\/]}, '_').underscore.gsub(/_{2,}/, '_').gsub(/_id(s?)$/, '_no\1')
      end

      def remote_name(object_field)
        object_field['key'] # TODO: y?!
      end

      def import(object_field)
        backend_class(object_field).new(object_name, local_name(object_field), object_field)
      end

      def backend_class(object_field)
        "Import::Zendesk::ObjectAttribute::#{object_field.type.capitalize}".constantize
      end

      def object_name
        self.class.name.to_s.sub(/Import::Zendesk::/, '').sub(/Field/, '')
      end
    end
  end
end
