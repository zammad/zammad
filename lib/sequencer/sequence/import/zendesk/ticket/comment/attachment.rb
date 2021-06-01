# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Sequence
    module Import
      module Zendesk
        class Ticket < Sequencer::Sequence::Base
          class Comment < Sequencer::Sequence::Base
            class Attachment < Sequencer::Sequence::Base

              def self.sequence
                [
                  'Import::Zendesk::Ticket::Comment::Attachment::Request',
                  'Import::Zendesk::Ticket::Comment::Attachment::Add',
                ]
              end
            end
          end
        end
      end
    end
  end
end
