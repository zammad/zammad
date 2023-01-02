# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Freshdesk::Mapping::CustomFields < Sequencer::Unit::Base
  include ::Sequencer::Unit::Import::Common::Mapping::Mixin::ProvideMapped

  uses :resource, :field_map, :model_class

  def process
    provide_mapped do
      custom_fields
    end
  end

  private

  def custom_fields
    resource['custom_fields'].each_with_object({}) do |(freshdesk_name, value), result|
      local_name = custom_fields_map[freshdesk_name]

      next if local_name.blank?

      result[ local_name.to_sym ] = value
    end
  end

  def custom_fields_map
    @custom_fields_map ||= field_map[model_class.name]
  end
end
