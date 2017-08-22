class Sequencer
  class Sequence
    module Import
      module Exchange
        class AvailableFolders < Sequencer::Sequence::Base

          def self.expecting
            [:folders]
          end

          def self.sequence
            [
              'Exchange::Connection',
              'Exchange::Folders::IdPathMap',
              'Import::Exchange::AttributeMapper::AvailableFolders',
            ]
          end
        end
      end
    end
  end
end
