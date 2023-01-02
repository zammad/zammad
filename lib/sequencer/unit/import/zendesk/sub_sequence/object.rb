# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::SubSequence::Object < Sequencer::Unit::Base
  include ::Sequencer::Unit::Import::Zendesk::SubSequence::Base
  include ::Sequencer::Unit::Import::Zendesk::SubSequence::Mapped

  private

  def expecting
    :instance
  end

  def mapping_value(expected_value)
    expected_value.id
  end
end
