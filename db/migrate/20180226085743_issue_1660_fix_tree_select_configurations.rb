# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Issue1660FixTreeSelectConfigurations < ActiveRecord::Migration[5.1]
  def change

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    return if attributes.blank?

    attributes.each do |attribute|

      next if attribute.data_option.blank?
      next if attribute.data_option[:options].blank?

      fixed_options = fix(attribute.data_option[:options])

      attribute.data_option[:options] = fixed_options

      attribute.save!
    end
  end

  private

  def attributes
    @attributes ||= ObjectManager::Attribute.where(data_type: 'tree_select')
  end

  def fix(options, namespace = nil)

    options.tap do |ref|

      ref.each do |option|

        option_namespace = Array(namespace.dup)
        option_namespace.push(option['name'])

        option['value'] = option_namespace.join('::')

        next if option['children'].blank?

        option['children'] = fix(option['children'], option_namespace)
      end
    end
  end
end
