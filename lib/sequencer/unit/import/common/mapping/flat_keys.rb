# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Common::Mapping::FlatKeys < Sequencer::Unit::Base
  include ::Sequencer::Unit::Import::Common::Mapping::Mixin::ProvideMapped
  prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

  skip_any_action

  uses :resource
  provides :mapped

  def process
    provide_mapped do
      mapped
    end
  end

  private

  def mapped
    @mapped ||= begin
      resource_with_indifferent_access = resource.with_indifferent_access
      mapping.symbolize_keys.to_h do |source, local|
        [local, resource_with_indifferent_access[source]]
      end.with_indifferent_access
    end
  end

  def mapping
    raise "Missing implementation of '#{__method__}' method for '#{self.class.name}'"
  end
end
