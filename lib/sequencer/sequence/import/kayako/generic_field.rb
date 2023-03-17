# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Sequence::Import::Kayako::GenericField < Sequencer::Sequence::Base

  def self.sequence
    [
      'Import::Kayako::Request',
      'Import::Kayako::Resources',
      'Import::Kayako::Perform',
    ]
  end
end
