# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::Organization::CustomFields < Sequencer::Unit::Import::Zendesk::Common::CustomFields

  private

  def remote_fields
    resource.organization_fields
  end
end
