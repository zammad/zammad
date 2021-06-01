# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class GitLabSupport < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'GitLab integration',
      name:        'gitlab_integration',
      area:        'Integration::Switch',
      description: 'Defines if the GitLab (http://www.gitlab.com) integration is enabled or not.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'gitlab_integration',
            tag:     'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state:       false,
      preferences: {
        prio:           1,
        authentication: true,
        permission:     ['admin.integration'],
      },
      frontend:    true
    )
    Setting.create_if_not_exists(
      title:       'GitLab config',
      name:        'gitlab_config',
      area:        'Integration::GitLab',
      description: 'Stores the GitLab configuration.',
      options:     {},
      state:       {
        endpoint: 'https://gitlab.com/api/graphql',
      },
      preferences: {
        prio:       2,
        permission: ['admin.integration'],
      },
      frontend:    false,
    )
  end

end
