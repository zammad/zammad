# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The field layer's options (Service::EntityAttribute::Option) as the form's fields take them.
module FormUpdater::OptionList
  # @param integer [Boolean] whether the values are record IDs
  # @param tree [Boolean] whether the field shows a tree, which marks the parents the user may not choose
  def self.form_options(options, integer: false, tree: false)
    options.map do |option|
      item = { value: integer ? option.value.to_i : option.value, label: option.label }
      item[:disabled] = option.disabled if tree
      item[:children] = form_options(option.children, integer:, tree:) if option.children.any?

      item
    end
  end
end
