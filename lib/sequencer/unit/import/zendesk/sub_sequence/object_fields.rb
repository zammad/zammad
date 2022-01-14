# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

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
