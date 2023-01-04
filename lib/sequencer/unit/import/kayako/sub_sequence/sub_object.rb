# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::SubSequence::SubObject < Sequencer::Unit::Import::Kayako::SubSequence::Generic

  uses :instance

  def sequence_params
    super.merge(
      instance: instance,
    )
  end
end
