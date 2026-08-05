# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AIKnowledgeBaseAnswerSuggestions < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    add_new_admin_permission
    add_feature_flag_setting
    add_relevance_score_setting
    move_kb_answer_generation_setting_permission
    drop_old_admin_permission
  end

  private

  def add_new_admin_permission
    Permission.create_if_not_exists(
      name:        'admin.ai_knowledge_base',
      label:       'AI Knowledge Base',
      description: 'Manage AI features which operate on your knowledge base content.',
      preferences: { prio: 1339 }
    )
  end

  def drop_old_admin_permission
    Permission.find_by(name: 'admin.ai_assistance_kb_answer_from_ticket_generation')&.destroy
  end

  def add_feature_flag_setting
    Setting.create_if_not_exists(
      title:       'AI Knowledge Base Answer Suggestions',
      name:        'ai_assistance_kb_answer_suggestions',
      area:        'AI::Assistance',
      description: 'Enable or disable the display of AI suggested knowledge base answers in the ticket sidebar.',
      options:     {},
      state:       true,
      preferences: {
        authentication: true,
        permission:     ['admin.ai_knowledge_base'],
      },
      frontend:    true,
    )
  end

  def add_relevance_score_setting
    Setting.create_if_not_exists(
      title:       'AI Knowledge Base Answer Suggestions Relevance Score',
      name:        'ai_assistance_kb_answer_suggestions_relevance_score',
      area:        'AI::Assistance',
      description: 'Defines the minimum relevance score (in percent) a knowledge base answer must reach to be suggested in the ticket sidebar.',
      options:     {
        form: [
          {
            display: '',
            null:    false,
            name:    'ai_assistance_kb_answer_suggestions_relevance_score',
            tag:     'integer',
            min:     0,
            max:     100,
          },
        ],
      },
      state:       86,
      preferences: {
        authentication: true,
        permission:     ['admin.ai_knowledge_base'],
        validations:    [
          'Setting::Validation::AIRelevanceScore',
        ],
      },
      frontend:    true,
    )
  end

  # Knowledge base answer generation is configured on the knowledge base screen now, so it has to
  # be writable by its administrators. The former permission stays around, but is inactive since
  # HideAIKbAnswerGenerationPermission.
  def move_kb_answer_generation_setting_permission
    setting = Setting.find_by(name: 'ai_assistance_kb_answer_from_ticket_generation')
    return if !setting

    setting.preferences[:permission] = ['admin.ai_knowledge_base']
    setting.save!
  end
end
