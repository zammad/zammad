# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module SubSequence
          class Object < Sequencer::Unit::Base
            include ::Sequencer::Unit::Import::Zendesk::SubSequence::Base
            include ::Sequencer::Unit::Import::Zendesk::SubSequence::Mapped

            private

            def expecting
              :instance
            end

            def mapping_value(expected_value)
              expected_value.id
            end
          end
        end
      end
    end
  end
end
