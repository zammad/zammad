# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

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
