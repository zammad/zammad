# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::User::OrganizationId < Sequencer::Unit::Common::Provider::Named

  uses :resource, :organization_map

  private

  def organization_id
    remote_id = resource.organization_id
    return if remote_id.blank?

    organization_map[remote_id]
  end
end
