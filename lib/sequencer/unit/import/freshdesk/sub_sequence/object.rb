# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Freshdesk::SubSequence::Object < Sequencer::Unit::Import::Freshdesk::SubSequence::Generic

  def sequence_name
    'Sequencer::Sequence::Import::Freshdesk::GenericObject'.freeze
  end
end
