# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::Case::StateId < Sequencer::Unit::Common::Provider::Named

  uses :resource

  private

  def state_id
    ::Ticket::State.select(:id).find_by(name: local).id
  end

  def local
    mapping.fetch(resource['status']['type'], 'open')
  end

  def mapping
    {
      'NEW'       => 'new',
      'OPEN'      => 'open',
      'PENDING'   => 'pending reminder',
      'COMPLETED' => 'closed',
      'CLOSED'    => 'closed',
      'CUSTOM'    => 'open',
    }.freeze
  end
end
