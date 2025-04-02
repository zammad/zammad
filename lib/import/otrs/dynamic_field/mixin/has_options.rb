# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Import::OTRS::DynamicField::Mixin::HasOptions
  extend ActiveSupport::Concern

  # Method to build nested structure
  def build_options_tree_structure(data)
    # Transform data into a hierarchical structure
    hierarchy = {}
    data.each do |path, name|
      current_level = hierarchy
      segments = path.split('::')

      segments.each_with_index do |segment, index|
        current_level[segment] ||= {}

        # Assign name to the last segment
        if index == segments.size - 1
          current_level[segment][:name] = name
        end
        current_level = current_level[segment]
      end
    end

    # Recursively build the array structure from the hierarchy.
    build_options_array_structure(hierarchy)
  end

  def build_options_array_structure(hierarchy)
    hierarchy.filter_map do |key, value|
      if value.is_a?(Hash) && value.key?(:name)
        # Using except to exclude the :name key
        children = value.except(:name)
        node = { 'value' => key, 'name' => value[:name] }
        node['children'] = build_options_array_structure(children) if children.any?
        node
      end
    end
  end

  def option_list(possible_values, tree_select)
    return possible_values if !tree_select

    build_options_tree_structure(possible_values)
  end
end
