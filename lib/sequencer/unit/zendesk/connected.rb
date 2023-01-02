# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Zendesk::Connected < Sequencer::Unit::Common::Provider::Named

  uses :client

  private

  def connected
    client.current_user.id.present?
  end
end
