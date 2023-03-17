# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::User::Login < Sequencer::Unit::Common::Provider::Named

  uses :resource

  private

  def login
    # Zendesk users may have no other identifier than the ID, e.g. twitter users
    resource.email || resource.id.to_s
  end
end
