# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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
        return if record.send("#{attr}_came_from_user?")

        record.send method_name, build_value(config)
      end

      def build_value(config)
        method_name = "build_value_#{config[:data_type]}"

        return send(method_name, config) if respond_to?(method_name, true)

        config[:default]
      end

      def build_value_date(config)
        diff = config[:diff]

        return if !diff

        Time.use_zone(Setting.get('timezone_default_sanitized')) do
          diff
            .days
            .from_now
            .to_date
        end
      end

      def build_value_datetime(config)
        diff = config[:diff]

        return if !diff

        Time.use_zone(Setting.get('timezone_default_sanitized')) do
          diff
            .hours
            .from_now
            .change(usec: 0, sec: 0)
            .utc
        end
      end

      def attributes_for(record)
        query     = ObjectManager::Attribute.active.editable.for_object(record.class)
        cache_key = "#{query.cache_key_with_version}/attribute_defaults"

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
