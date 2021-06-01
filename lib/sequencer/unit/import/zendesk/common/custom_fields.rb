# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module Common
          class CustomFields < Sequencer::Unit::Base
            include ::Sequencer::Unit::Import::Common::Mapping::Mixin::ProvideMapped

            uses :resource

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

                result[key] = value
              end
            end
          end
        end
      end
    end
  end
end
