# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::Ticket::StateId < Sequencer::Unit::Common::Provider::Named

  uses :resource

  private

  def state_id
    return default_state_id if local.blank?

    ::Ticket::State.select(:id).find_by(name: local)&.id || default_state_id
  end

  def local
    # When no mapping exist, try to find state in database.
    mapping.fetch(resource.status, resource.status)
  end

  def mapping
    {
      'new'     => 'new',
      'pending' => 'pending reminder',
      'solved'  => 'closed',
      'hold'    => 'open'
    }.freeze
  end

  def default_state_id
    @default_state_id ||= ::Ticket::State.find_by(name: 'open')&.id
  end
end
