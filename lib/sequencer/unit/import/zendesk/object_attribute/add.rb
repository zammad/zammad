# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::ObjectAttribute::Add < Sequencer::Unit::Base
  prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

  skip_action :skipped, :failed

  uses :model_class, :sanitized_name, :resource, :backend_class
  provides :instance

  def process
    state.provide(:instance) do
      backend_class.new(model_class, sanitized_name, resource)
    end
  end
end
