# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Common::Model::Statistics::Total < Sequencer::Unit::Base
  include ::Sequencer::Unit::Import::Common::Model::Statistics::Mixin::EmptyDiff

  def process
    state.provide(:statistics_diff) do
      diff.merge(
        total: total
      )
    end
  end

  private

  def total
    raise "Missing implementation if total method for class #{self.class.name}"
  end
end
