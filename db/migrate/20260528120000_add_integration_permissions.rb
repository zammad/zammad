# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AddIntegrationPermissions < ActiveRecord::Migration[8.0]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    add_permissions
    grant_to_existing_agent_roles
  end

  def down
    %w[
      integration.idoit
      integration.github
      integration.gitlab
      integration
    ].each do |name|
      Permission.find_by(name:)&.destroy
    end
  end

  def add_permissions
    Permission.create_if_not_exists(
      name:        'integration',
      label:       'Integration',
      description: 'Access to third-party integrations in the ticket interface.',
      preferences: {
        prio:     1720,
        disabled: true,
      },
    )
    {
      'integration.idoit'  => 'i-doit',
      'integration.github' => 'GitHub',
      'integration.gitlab' => 'GitLab',
    }.each_with_index do |(name, label), index|
      Permission.create_if_not_exists(
        name:        name,
        label:       label,
        description: "Access the #{label} integration features.",
        preferences: { prio: 1730 + (index * 10) },
      )
    end
  end

  # Preserve the existing behaviour: every role that can currently use the
  #   integrations (i.e. holds 'ticket.agent') keeps access after the upgrade.
  #   Admins can then revoke it per role as needed.
  def grant_to_existing_agent_roles
    Role.with_permissions('ticket.agent').each do |role|
      role.permission_grant('integration.idoit')
      role.permission_grant('integration.github')
      role.permission_grant('integration.gitlab')
    end
  end
end
