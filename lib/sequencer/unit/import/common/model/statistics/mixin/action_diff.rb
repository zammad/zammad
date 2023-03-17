# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Sequencer::Unit::Import::Common::Model::Statistics::Mixin::ActionDiff
  include Sequencer::Unit::Import::Common::Model::Statistics::Mixin::Common

  def self.included(base)
    base.uses :action
    base.provides :statistics_diff
  end

  private

  def diff
    raise "Unknown action '#{action}'" if !possible?

    empty_diff.merge(
      action => 1,
      sum: 1,
    )
  end

  def possible?
    possible_actions.include?(action)
  end
end
