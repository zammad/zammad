# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::Ticket::GroupId < Sequencer::Unit::Common::Provider::Named

  uses :resource, :group_map

  private

  def group_id
    group_map.fetch(resource.group_id, 1)
  end
end
