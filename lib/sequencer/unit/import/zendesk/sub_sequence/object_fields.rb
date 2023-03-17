# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::SubSequence::ObjectFields < Sequencer::Unit::Base
  include ::Sequencer::Unit::Import::Zendesk::SubSequence::Base
  include ::Sequencer::Unit::Import::Zendesk::SubSequence::Mapped

  private

  def expecting
    :sanitized_name
  end
end
