# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Sequencer::Unit::Import::Common::Model::Statistics::Mixin::EmptyDiff
  include Sequencer::Unit::Import::Common::Model::Statistics::Mixin::Common

  def self.included(base)
    base.provides :statistics_diff
  end

  alias diff empty_diff
end
