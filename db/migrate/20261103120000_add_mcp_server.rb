# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AddMCPServer < ActiveRecord::Migration[8.1]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    create_mcp_confirmations
    add_mcp_setting
    add_cleanup_scheduler
  end

  private

  # May exist already, from a development version of the MCP server.
  def create_mcp_confirmations
    create_table :ai_mcp_confirmations, id: :integer, if_not_exists: true do |t|
      t.string :request_id, limit: 36, null: false
      t.string :action_digest, limit: 64, null: false
      t.datetime :expires_at, limit: 3, null: false
      t.datetime :consumed_at, limit: 3
      t.timestamps limit: 3, null: false

      t.index :request_id, unique: true
      t.index :expires_at
    end
  end

  def add_mcp_setting
    Setting.create_if_not_exists(
      title:       'MCP server',
      name:        'api_mcp_access',
      area:        'API::Base',
      description: 'Enable the MCP server, so that AI clients can use Zammad with personal access tokens.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'api_mcp_access',
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
        permission: ['admin.api'],
      },
      frontend:    false,
    )
  end

  def add_cleanup_scheduler
    Scheduler.create_if_not_exists(
      name:          'Delete expired MCP confirmations.',
      method:        'AI::MCPConfirmation.cleanup',
      period:        1.day,
      prio:          2,
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
      last_run:      Time.current,
    )
  end
end
