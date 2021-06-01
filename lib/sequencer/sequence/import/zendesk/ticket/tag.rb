# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Sequence
    module Import
      module Zendesk
        class Ticket < Sequencer::Sequence::Base
          class Tag < Sequencer::Sequence::Base

            def self.sequence
              [
                'Import::Zendesk::Ticket::Tag::Item',
                'Common::Tag::Add',
              ]
            end
          end
        end
      end
    end
  end
end
