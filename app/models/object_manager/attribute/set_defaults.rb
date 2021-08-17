# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ObjectManager
  class Attribute
    class SetDefaults
      def after_initialize(record)
        return if !record.new_record?

        attributes_for(record).each { |attr, config| set_value(record, attr, config) }
      end

      private

      def set_value(record, attr, config)
        method_name = "#{attr}="

        return if !record.respond_to? method_name
        return if record.send(attr).present?

        record.send method_name, build_value(config)
      end

      def build_value(config)
        case config[:data_type]
        when 'date'
          config[:diff].days.from_now
        when 'datetime'
          config[:diff].hours.from_now
        else
          config[:default]
        end
      end

      def attributes_for(record)
        query     = ObjectManager::Attribute.active.editable.for_object(record.class)
        cache_key = "#{query.cache_key}/attribute_defaults"

        Rails.cache.fetch cache_key do
          query
            .map { |attr| { attr.name => config_of(attr) } }
            .reduce({}, :merge)
            .compact
        end
      end

      def config_of(attr)
        case attr.data_type
        when 'date', 'datetime'
          {
            data_type: attr.data_type,
            diff:      attr.data_option&.dig(:diff)
          }
        else
          {
            data_type: attr.data_type,
            default:   attr.data_option&.dig(:default)
          }
        end
      end
    end
  end
end
