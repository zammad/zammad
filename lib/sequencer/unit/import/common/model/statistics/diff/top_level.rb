# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Common::Model::Statistics::Diff::TopLevel < Sequencer::Unit::Base
  include ::Sequencer::Unit::Import::Common::Model::Statistics::Mixin::ActionDiff

  def process
    state.provide(:statistics_diff, diff)
  end
end
