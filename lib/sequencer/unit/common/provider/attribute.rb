# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Common::Provider::Attribute < Sequencer::Unit::Base

  def process
    return if ignore?

    state.provide(attribute, value)
  end

  private

  def attribute
    @attribute ||= provides
  end

  def provides
    provides_list = self.class.provides
    raise "Only single provide attribute possible for class #{self.class.name}" if provides_list.size != 1

    provides_list.first
  end

  def value
    @value ||= send(attribute)
  end

  def ignore?
    # don't store nil values which are default anyway
    value.nil?
  end
end
