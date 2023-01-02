# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::Common::CustomFields < Sequencer::Unit::Base
  include ::Sequencer::Unit::Import::Common::Mapping::Mixin::ProvideMapped

  uses :resource, :field_map, :model_class

  def process
    provide_mapped do
      attributes_hash
    end
  end

  private

  def remote_fields
    raise 'Missing implementation of remote_fields method'
  end

  def fields
    @fields ||= remote_fields
  end

  def attributes_hash
    return {} if fields.blank?

    fields.each_with_object({}) do |(key, value), result|
      next if value.nil?

      if custom_fields_map.nil?
        result[key] = value
      else
        local_name = custom_fields_map[key]
        result[ local_name.to_sym ] = value
      end

    end
  end

  def custom_fields_map
    @custom_fields_map ||= begin
      if model_class
        field_map[model_class.name]
      end
    end
  end
end
