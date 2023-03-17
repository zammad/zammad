# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Freshdesk::Ticket::Tags < Sequencer::Unit::Common::Model::Tags

  uses :resource

  private

  def tags
    resource['tags']
  end
end
