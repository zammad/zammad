# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Common::RemoteId::CaseInsensitive < Sequencer::Unit::Base

  uses :remote_id
  provides :remote_id

  def process
    state.provide(:remote_id) do
      remote_id.downcase
    end
  end
end
