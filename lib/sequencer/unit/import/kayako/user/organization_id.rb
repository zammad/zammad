# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::User::OrganizationId < Sequencer::Unit::Common::Provider::Named

  uses :resource, :id_map

  private

  def organization_id
    remote_id = resource['organization']&.fetch('id')
    return if remote_id.blank?

    id_map['Organization'][remote_id]
  end
end
