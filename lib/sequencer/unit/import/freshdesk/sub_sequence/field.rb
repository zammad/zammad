# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Freshdesk
        module SubSequence
          class Field < Sequencer::Unit::Import::Freshdesk::SubSequence::Generic

            def sequence_name
              'Sequencer::Sequence::Import::Freshdesk::GenericField'.freeze
            end
          end
        end
      end
    end
  end
end
