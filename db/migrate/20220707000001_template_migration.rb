# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class TemplateMigration < ActiveRecord::Migration[6.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    article_attribute_list = %w[body form_id]

    Template.all.each do |template|
      new_options = {}
      template.options.each do |key, value|
        new_key = "ticket.#{key}"
        if article_attribute_list.include?(key)
          new_key = "article.#{key}"
        end
        new_options[new_key] = value
      end
      template.options = new_options
      template.save!
    end

  end
end
