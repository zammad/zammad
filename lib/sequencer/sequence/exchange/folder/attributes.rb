class Sequencer
  class Sequence
    module Exchange
      module Folder
        class Attributes < Sequencer::Sequence::Base

          def self.sequence
            [
              'Exchange::Connection',
              'Exchange::Folder::Attributes',
            ]
          end
        end
      end
    end
  end
end
