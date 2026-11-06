# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# How a caller names an object as people know it — a ticket by its number, ID or link, a user by ID or email — and how
#   the named one is found, one class per type in this directory: a tool that loads a named object gets the type's
#   parameters, and an addon adds a type the same way, without a list to change. A locator checks nothing about what the
#   caller may see: the tool loads the object with its policy, so that an object the caller may not see and one that
#   does not exist read alike.
class Service::AI::Tool::Locator
  # How an agent names an object in a message by its ID, as the tools show it.
  ID_IN_TEXT = %r{\bID[[:space:]:#]*(\d+)\b}i

  class_attribute :object_type, instance_accessor: false

  attr_reader :arguments

  # @param arguments [Hash] the tool's arguments, with string keys
  def initialize(arguments)
    @arguments = arguments
  end

  class << self
    # @param type [Class] the model a tool loads
    # @return [Class, nil] the locator of objects of the type
    def for_type(type)
      descendants.find { |locator| locator.object_type == type }
    end

    # Whether the caller named an object at all.
    def named?(arguments)
      self::PARAMETERS.keys.any? { |name| !arguments[name].nil? }
    end

    # @return [Array<String>] what is wrong with how the object is named, empty when it can be looked for
    def argument_errors(_arguments)
      []
    end

    private

    # @param type [Class] the model whose objects the locator finds
    def locates(type)
      self.object_type = type
    end
  end

  # Last, because loading the types runs their declarations, which need the methods above.
  include Mixin::RequiredSubPaths
end
