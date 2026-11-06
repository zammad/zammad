# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# One option of a tree, or several: stored by its path, its parts joined with "::", and given by that path, its parts
#   joined as in the UI, or its last part where that fits one option only.
class Service::EntityAttribute::Type::TreeSelect < Service::EntityAttribute::Type::Select
  handles 'tree_select', 'multi_tree_select'

  def label(value)
    value
  end

  private

  def normalize(value)
    value.squish.gsub(%r{\s*(?:›|::|>)\s*}, '::')
  end

  # By its path, which tells two options of the same name apart.
  def choice_label(option)
    option.value
  end

  def short_name(pair)
    pair.first.split('::').last
  end
end
