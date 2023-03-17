# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::Ticket::UserId < Sequencer::Unit::Common::Provider::Named

  uses :resource, :user_map

  private

  def user_id
    user_map.fetch(resource.requester_id, 1)
  end
end
