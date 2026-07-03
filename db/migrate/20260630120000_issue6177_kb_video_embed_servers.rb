# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Issue6177KbVideoEmbedServers < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Knowledge base self-hosted video servers',
      name:        'kb_self_hosted_video_servers',
      area:        'Kb::Core',
      description: 'List of self-hosted video servers. This list is used for content security policy.',
      options:     {},
      state:       [],
      preferences: {
        permission:  ['admin.knowledge_base'],
        validations: ['Setting::Validation::KbSelfHostedVideoServers'],
      },
      frontend:    true,
    )
  end
end
