# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Sequence::Import::Zendesk::Ticket < Sequencer::Sequence::Base
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
