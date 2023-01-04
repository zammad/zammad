# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Sequencer::Unit::Import::Common::Model::Mixin::HandleFailure

  def self.included(base)
    base.provides :exception, :action
  end

  def handle_failure(e)
    logger.error(e)
    state.provide(:exception, e)
    state.provide(:action, :failed)
  end
end
