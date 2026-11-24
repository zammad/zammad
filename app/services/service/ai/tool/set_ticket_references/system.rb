# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# A system outside Zammad a ticket can reference — GitHub, GitLab, i-doit —, one class per system in this directory:
#   its name in the tool's arguments, the integration that switches it on, how a value the caller gives is found there
#   and how the ticket stores it. An addon adds a system the same way, without a list to change.
class Service::AI::Tool::SetTicketReferences::System
  # A value the system does not take, with a reason the model can act on.
  class Refusal < StandardError
    attr_reader :code

    # @param code [String] 'not_found', 'invalid_value', or 'unavailable' for a system that did not answer
    def initialize(reason, code: 'not_found')
      super(reason)
      @code = code
    end
  end

  class_attribute :system_name, :label, :noun, :setting, instance_accessor: false

  class << self
    # @return [Array<Class>] every system, apart from the shared parents
    def all
      descendants.select(&:system_name).sort_by(&:system_name)
    end

    def names
      all.map(&:system_name)
    end

    def named(name)
      all.find { |system| system.system_name == name }
    end

    def active
      all.select(&:active?)
    end

    def active?
      Setting.get(setting).present?
    end

    # Asks the system, so it runs outside the ticket's lock.
    #
    # @param value [String] as the caller gave it
    # @return [Object] what the ticket stores for it
    # @raise [Refusal]
    def resolve(_value)
      raise NotImplementedError
    end

    # @return [Array] what the ticket stores, in its order
    def stored(_ticket)
      raise NotImplementedError
    end

    def store(_ticket, _values)
      raise NotImplementedError
    end

    # The stored value the caller means, to remove it.
    #
    # @return [Object, nil]
    def stored_match(_stored, _value)
      raise NotImplementedError
    end

    # Checked before the system is asked, for a reference to add as well as one to remove.
    #
    # @return [String, nil] why the value cannot name a reference of the system
    def value_error(_value)
      nil
    end

    def refuse(reason, code: 'not_found')
      raise Refusal.new(reason, code:)
    end

    private

    # @param name [String] the system in the tool's arguments and in the ticket's preferences
    # @param label [String] the system's name in a text
    # @param noun [String] what a reference of the system is, in a text
    # @param setting [String] the setting that switches its integration on
    def references(name, label:, noun:, setting:)
      self.system_name = name
      self.label       = label
      self.noun        = noun
      self.setting     = setting
    end
  end

  # Last, because loading the systems runs their declarations, which need the methods above.
  include Mixin::RequiredSubPaths
end
