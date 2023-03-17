# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::Ticket::StateId < Sequencer::Unit::Common::Provider::Named

  uses :resource

  private

  def state_id
    ::Ticket::State.select(:id).find_by(name: local).id
  end

  def local
    mapping.fetch(resource.status, resource.status)
  end

  def mapping
    {
      'pending' => 'pending reminder',
      'solved'  => 'closed',
      'deleted' => 'removed',
      'hold'    => 'open'
    }.freeze
  end
end
