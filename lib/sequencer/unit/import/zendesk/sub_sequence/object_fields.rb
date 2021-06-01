# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module SubSequence
          class ObjectFields < Sequencer::Unit::Base
            include ::Sequencer::Unit::Import::Zendesk::SubSequence::Base
            include ::Sequencer::Unit::Import::Zendesk::SubSequence::Mapped

            private

            def expecting
              :sanitized_name
            end
          end
        end
      end
    end
  end
end
