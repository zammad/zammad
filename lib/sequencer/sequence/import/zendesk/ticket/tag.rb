# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Sequence::Import::Zendesk::Ticket < Sequencer::Sequence::Base
  class Tag < Sequencer::Sequence::Base

    def self.sequence
      [
        'Import::Zendesk::Ticket::Tag::Item',
        'Common::Tag::Add',
      ]
    end
  end
end
