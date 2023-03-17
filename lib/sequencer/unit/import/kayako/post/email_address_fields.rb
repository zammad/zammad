# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::Post::EmailAddressFields < Sequencer::Unit::Base

  uses :resource, :id_map
  provides :from, :to, :cc

  def process
    state.provide(:user_id) do
      user_map.fetch(resource.author_id, 1)
    end
  end

end
