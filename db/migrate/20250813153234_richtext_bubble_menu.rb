# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class RichtextBubbleMenu < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    add_bubble_menu_setting
    migrate_article_body_attribute
  end

  private

  def add_bubble_menu_setting
    Setting.create_if_not_exists(
      title:       'Richtext Bubble Menu',
      name:        'ui_richtext_bubble_menu',
      area:        'UI::Richtext',
      description: 'Defines if the bubble menu feature of the richtext editor is enabled. Note that this setting will be ignored if the writing assistant is turned on.',
      options:     {
        form: [
          {
            display:   '',
            null:      true,
            name:      'ui_richtext_bubble_menu',
            tag:       'boolean',
            translate: true,
            options:   {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state:       true,
      preferences: {
        permission: ['admin.ui'],
      },
      frontend:    true,
    )
  end

  def migrate_article_body_attribute
    attribute = ObjectManager::Attribute.find_by(object_lookup_id: ObjectLookup.by_name('TicketArticle'), name: 'body')
    return if attribute.blank?

    attribute.data_option['bubble_menu'] = true
    attribute.data_option.delete('text_tools') if attribute.data_option.key?('text_tools')

    attribute.save!
  end
end
