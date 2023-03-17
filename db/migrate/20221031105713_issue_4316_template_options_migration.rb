# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue4316TemplateOptionsMigration < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Template.all.each do |template|
      template.options = migrate_template_options(template.options)
      template.save!
    end
  end

  private

  def migrate_template_options(options)
    new_options = {}

    options.each do |key, value|
      next if key.ends_with?('_completion')

      if value.is_a?(Hash)
        new_options[key] = value
        next
      end

      new_options[key] = { value: value }

      if options.key?("#{key}_completion")
        new_options[key]['value_completion'] = options["#{key}_completion"]
      end
    end

    new_options
  end
end
