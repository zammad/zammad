# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::Ticket::Comment::UserId < Sequencer::Unit::Base

  uses :resource, :user_map
  provides :user_id

  def process
    state.provide(:user_id) do
      user_map.fetch(resource.author_id, 1)
    end
  end
end
