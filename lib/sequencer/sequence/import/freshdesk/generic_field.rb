class Sequencer
  class Sequence
    module Import
      module Freshdesk
        class GenericField < Sequencer::Sequence::Base

          def self.sequence
            [
              'Import::Freshdesk::Request',
              'Import::Freshdesk::Resources',
              'Import::Freshdesk::Perform',
            ]
          end
        end
      end
    end
  end
end
