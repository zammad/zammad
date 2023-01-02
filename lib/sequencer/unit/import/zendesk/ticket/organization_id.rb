# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::Ticket::OrganizationId < Sequencer::Unit::Common::Provider::Named

  uses :resource, :organization_map

  private

  def organization_id
    organization_map[resource.organization_id]
  end
end
