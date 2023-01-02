# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Common::Model::Create < Sequencer::Unit::Base
  include ::Sequencer::Unit::Import::Common::Model::Mixin::HandleFailure
  prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

  skip_any_action

  uses :mapped, :model_class
  provides :instance, :action

  def process
    instance = model_class.new(mapped)

    state.provide(:instance, instance)
    state.provide(:action, :created)
  rescue => e
    handle_failure(e)
  end
end
