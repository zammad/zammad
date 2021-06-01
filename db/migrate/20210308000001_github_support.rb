# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class GitHubSupport < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'GitHub integration',
      name:        'github_integration',
      area:        'Integration::Switch',
      description: 'Defines if the GitHub (http://www.github.com) integration is enabled or not.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'github_integration',
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
      title:       'GitHub config',
      name:        'github_config',
      area:        'Integration::GitHub',
      description: 'Stores the GitHub configuration.',
      options:     {},
      state:       {
        endpoint: 'https://api.github.com/graphql',
      },
      preferences: {
        prio:       2,
        permission: ['admin.integration'],
      },
      frontend:    false,
    )
  end

end
