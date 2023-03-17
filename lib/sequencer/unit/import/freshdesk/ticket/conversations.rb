# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Freshdesk::Ticket::Conversations < Sequencer::Unit::Import::Freshdesk::SubSequence::Generic
  prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

  optional :action

  skip_action :skipped, :failed

  uses :resource

  def sequence_name
    'Sequencer::Sequence::Import::Freshdesk::Conversations'.freeze
  end

  def request_params
    super.merge(
      ticket: resource,
    )
  end
end
