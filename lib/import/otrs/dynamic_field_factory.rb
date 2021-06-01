# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Import
  module OTRS
    module DynamicFieldFactory
      extend Import::Factory
      extend Import::Helper
      extend self

      def skip?(record, *_args)
        return true if skip_field?(record['Name'])
        return false if importable?(record)

        @skip_fields.push(record['Name'])
        true
      end

      def backend_class(record, *_args)
        "Import::OTRS::DynamicField::#{record['FieldType']}".constantize
      end

      def skip_field?(dynamic_field_name)
        skip_fields.include?(dynamic_field_name)
      end

      private

      def importable?(dynamic_field)
        return false if !supported_object_type?(dynamic_field)

        supported_field_type?(dynamic_field)
      end

      def supported_object_type?(dynamic_field)
        return true if dynamic_field['ObjectType'] == 'Ticket'

        log "ERROR: Unsupported dynamic field object type '#{dynamic_field['ObjectType']}' for dynamic field '#{dynamic_field['Name']}'"
        false
      end

      def supported_field_type?(dynamic_field)
        return true if supported_field_types.include?(dynamic_field['FieldType'])

        log "ERROR: Unsupported dynamic field field type '#{dynamic_field['FieldType']}' for dynamic field '#{dynamic_field['Name']}'"
        false
      end

      def supported_field_types
        %w[Text TextArea Checkbox DateTime Date Dropdown Multiselect]
      end

      def skip_fields
        return @skip_fields if @skip_fields

        @skip_fields = %w[ProcessManagementProcessID ProcessManagementActivityID ZammadMigratorChanged ZammadMigratorChangedOld]
      end
    end
  end
end
