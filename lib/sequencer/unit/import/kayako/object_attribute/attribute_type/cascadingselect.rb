# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::ObjectAttribute::AttributeType::Cascadingselect < Sequencer::Unit::Import::Kayako::ObjectAttribute::AttributeType::Select
  def local_value(value)
    super.gsub('\\', '::')
  end

  private

  def data_type
    'tree_select'
  end

  def options
    result = []

    attribute['options'].each do |item|
      locale_item = item['values'].detect { |value| value['locale'] == default_language }

      next if locale_item['translation'].nil?

      transformed_tree_path = locale_item['translation'].gsub('\\', '::')

      process_option(transformed_tree_path, result)
    end

    result
  end

  def process_option(tree_path, current_options, parent_tree_path = nil)
    fragments = tree_path.split('::')

    current_fragment = fragments.shift

    current_tree_path = parent_tree_path.nil? ? current_fragment : "#{parent_tree_path}::#{current_fragment}"

    current_option = current_options.detect { |option| option[:value] == current_tree_path }

    remaining_tree_path = fragments.join('::')

    if current_option.nil?
      current_options.push({ name: current_fragment, value: current_tree_path })

      current_option = current_options.last
    end

    return if remaining_tree_path.empty?

    current_option[:children] ||= []
    process_option(remaining_tree_path, current_option[:children], current_tree_path)
  end
end
