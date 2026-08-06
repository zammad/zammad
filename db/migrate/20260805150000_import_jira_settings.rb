# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class ImportJiraSettings < ActiveRecord::Migration[7.0]
  def up
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       __('Import Endpoint'),
      name:        'import_jira_endpoint',
      area:        'Import::Jira',
      description: __('Defines a Jira Cloud site URL to import projects, issues, users, and comments.'),
      options:     {
        form: [
          {
            display: '',
            null:    false,
            name:    'import_jira_endpoint',
            tag:     'input',
          },
        ],
      },
      state:       'https://yours.atlassian.net',
      frontend:    false
    )

    Setting.create_if_not_exists(
      title:       __('Import login for the Jira API'),
      name:        'import_jira_email',
      area:        'Import::Jira',
      description: __('Defines the email address of the Jira account used for API authentication.'),
      options:     {
        form: [
          {
            display: '',
            null:    false,
            name:    'import_jira_email',
            tag:     'input',
          },
        ],
      },
      state:       '',
      frontend:    false
    )

    Setting.create_if_not_exists(
      title:       __('Import API token for requesting the Jira API'),
      name:        'import_jira_api_token',
      area:        'Import::Jira',
      description: __('Defines the Jira API token used together with the email address for authentication.'),
      options:     {
        form: [
          {
            display: '',
            null:    false,
            name:    'import_jira_api_token',
            tag:     'input',
          },
        ],
      },
      state:       '',
      frontend:    false
    )

    Setting.create_if_not_exists(
      title:       __('Jira project key to import'),
      name:        'import_jira_project_key',
      area:        'Import::Jira',
      description: __('Defines the key of the Jira project (e.g. "LS") whose issues will be imported.'),
      options:     {
        form: [
          {
            display: '',
            null:    false,
            name:    'import_jira_project_key',
            tag:     'input',
          },
        ],
      },
      state:       '',
      frontend:    false
    )
  end
end
