# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::User::CustomFields < Sequencer::Unit::Import::Zendesk::Common::CustomFields

  private

  def remote_fields
    resource.user_fields
  end
end
