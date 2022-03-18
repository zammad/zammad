# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Kayako
        module Organization
          class Mapping < Sequencer::Unit::Base
            include ::Sequencer::Unit::Import::Common::Mapping::Mixin::ProvideMapped

            uses :resource

            def process
              provide_mapped do
                {
                  name:              resource['name'],
                  domain:            domain,
                  domain_assignment: domain.present?,
                }
              end
            end

            private

            def domain
              @domain ||= begin
                primary_domain = resource['domains']&.detect { |item| item['is_primary'] }
                primary_domain&.fetch('domain')
              end
            end
          end
        end
      end
    end
  end
end
