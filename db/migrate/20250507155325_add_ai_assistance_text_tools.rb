# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AddAIAssistanceTextTools < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    add_admin_permission
    add_feature_flag_setting
    migrate_article_body_attribute
  end

  private

  def add_admin_permission
    Permission.create_if_not_exists(
      name:        'admin.ai_assistance_text_tools',
      label:       'Writing Assistant',
      description: 'Manage writing assistant text tools of your system.',
      preferences: { prio: 1335 }
    )
  end

  def add_feature_flag_setting
    Setting.create_if_not_exists(
      title:       'Writing Assistant',
      name:        'ai_assistance_text_tools',
      area:        'AI::Assistance',
      description: 'Enable or disable the writing assistant text tools.',
      options:     {},
      state:       false,
      preferences: {
        authentication: true,
        permission:     ['admin.ai_assistance_text_tools'],
      },
      frontend:    true,
    )
  end

  def migrate_article_body_attribute
    attribute = ObjectManager::Attribute.find_by(object_lookup_id: ObjectLookup.by_name('TicketArticle'), name: 'body')
    return if attribute.blank?

    attribute.data_option['text_tools'] = true
    attribute.save!
  end
end
