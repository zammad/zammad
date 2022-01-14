# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module Organization
          class Mapping < Sequencer::Unit::Base
            include ::Sequencer::Unit::Import::Common::Mapping::Mixin::ProvideMapped

            uses :resource

            def process
              provide_mapped do
                {
                  name:   resource.name,
                  note:   resource.note,
                  shared: resource.shared_tickets,
                }
              end
            end
          end
        end
      end
    end
  end
end
