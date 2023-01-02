# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Sequencer::Unit::Import::Common::Model::Statistics::Mixin::Common
  private

  def actions
    %i[skipped created updated unchanged failed deactivated]
  end

  def results
    %i[sum total]
  end

  def empty_diff
    possible_actions.index_with { |_key| 0 }
  end

  def possible_actions
    @possible_actions ||= actions + results
  end
end
