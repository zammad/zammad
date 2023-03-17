# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Common::AttributeMapper < Sequencer::Unit::Base

  def self.map
    raise "Missing implementation of '#{__method__}' method for '#{name}'"
  end

  def self.uses
    map.keys
  end

  def self.provides
    map.values
  end

  def process
    self.class.map.each do |original, renamed|
      state.provide(renamed) do
        state.use(original)
      end
    end
  end
end
