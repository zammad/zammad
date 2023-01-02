# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Common::Model::Attributes::RemoteId < Sequencer::Unit::Base
  include ::Sequencer::Unit::Import::Common::Model::Mixin::HandleFailure

  uses :resource
  provides :remote_id

  def process
    state.provide(:remote_id) do
      resource.fetch(attribute).dup.to_s
    end
  rescue KeyError => e
    handle_failure(e)
  end

  private

  def attribute
    :id
  end
end
