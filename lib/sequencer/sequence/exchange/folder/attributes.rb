# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Sequence::Exchange::Folder::Attributes < Sequencer::Sequence::Base

  def self.sequence
    [
      'Exchange::Connection',
      'Exchange::Folder::Attributes',
    ]
  end
end
