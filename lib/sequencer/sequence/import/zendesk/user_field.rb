class Sequencer
  class Sequence
    module Import
      module Zendesk
        class UserField < Sequencer::Sequence::Base

          def self.sequence
            [
              'Common::ModelClass::User',
              'Import::Zendesk::ObjectAttribute::SanitizedName',
              'Import::Zendesk::ObjectAttribute::Add',
            ]
          end
        end
      end
    end
  end
end
