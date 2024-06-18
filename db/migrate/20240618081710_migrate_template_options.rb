# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class MigrateTemplateOptions < ActiveRecord::Migration[7.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Template.all.each do |template|
      if old_options?(template.options)
        template.options = migrate_options(template.options)
        template.save!
      end
    end
  end

  def old_options?(options)
    options.each_key do |key|
      return false if key.starts_with?(%r{(ticket|article)\.})
    end

    true
  end

  # Implements a compatibility layer for templates, by converting `options` to a newer format:
  #   options: {
  #     'ticket.field_1': { value: 'value_1' },
  #     'ticket.field_2': { value: 'value_2', value_completion: 'value_completion_2' },
  #   }
  def migrate_options(options)
    old_options = options.clone
    new_options = {}

    article_attribute_list = %w[body form_id]

    old_options.each do |key, value|
      new_key = "ticket.#{key}"

      if article_attribute_list.include?(key)
        new_key = "article.#{key}"
      end

      new_options[new_key] = { value: value }

      if old_options.key?("#{key}_completion")
        new_options[new_key]['value_completion'] = old_options["#{key}_completion"]
        old_options.delete("#{key}_completion")
      end
    end

    new_options
  end
end
