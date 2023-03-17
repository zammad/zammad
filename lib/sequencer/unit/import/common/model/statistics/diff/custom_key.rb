# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Common::Model::Statistics::Diff::CustomKey < Sequencer::Unit::Base
  include ::Sequencer::Unit::Import::Common::Model::Statistics::Mixin::ActionDiff

  def process
    state.provide(:statistics_diff) do
      {
        key => diff,
      }
    end
  end

  private

  def key
    raise "Missing implementation of method 'key' for class #{self.class.name}"
  end
end
