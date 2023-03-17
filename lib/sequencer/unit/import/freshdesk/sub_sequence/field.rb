# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Freshdesk::SubSequence::Field < Sequencer::Unit::Import::Freshdesk::SubSequence::Generic

  def sequence_name
    'Sequencer::Sequence::Import::Freshdesk::GenericField'.freeze
  end
end
