# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# One value of a field's list as a form shows it: stored as value, shown by its own label; in a tree with the values
#   below it, where a parent the caller may not choose stays to hold them, disabled.
Service::EntityAttribute::Option = Data.define(:value, :label, :disabled, :children) do
  def self.flatten(options)
    options.flat_map { |option| [option, *flatten(option.children)] }
  end

  def initialize(value:, label:, disabled: false, children: [])
    super
  end
end
