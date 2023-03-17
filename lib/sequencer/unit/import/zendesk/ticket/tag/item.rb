# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::Ticket::Tag::Item < Sequencer::Unit::Common::Provider::Named

  uses :resource

  def item
    resource.id
  end
end
