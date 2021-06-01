# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Freshdesk
        module Mapping
          class CustomFields < Sequencer::Unit::Base
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
                result[ local_name.to_sym ] = value
              end
            end

            def custom_fields_map
              @custom_fields_map ||= field_map[model_class.name]
            end
          end
        end
      end
    end
  end
end
