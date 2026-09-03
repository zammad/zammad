# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Jira::PermissionPresent < Sequencer::Unit::Common::Provider::Named
  extend ::Sequencer::Unit::Import::Jira::Requester

  private

  def permission_present
    data = self.class.get_json(
      'mypermissions',
      params: {
        projectKey:  Setting.get('import_jira_project_key'),
        permissions: 'BROWSE_PROJECTS',
      },
    )

    data&.dig('permissions', 'BROWSE_PROJECTS', 'havePermission') == true
  rescue => e
    logger.error e
    nil
  end
end
