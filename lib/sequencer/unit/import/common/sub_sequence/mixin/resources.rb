# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Sequencer::Unit::Import::Common::SubSequence::Mixin::Resources
  include ::Sequencer::Unit::Import::Common::SubSequence::Mixin::Base

  def process
    return if resources.blank?

    sequence_resources(resources)
  end

  private

  def resources
    raise "Missing implementation of '#{__method__}' method for '#{self.class.name}'"
  end
end
