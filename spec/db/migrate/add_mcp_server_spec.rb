# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AddMCPServer, :aggregate_failures, db_strategy: :reset, type: :db_migration do
  def schema
    connection = ActiveRecord::Base.connection

    {
      # Timestamps get precision 3 in create_base.rb (Migration[4.2]) only; `limit: 3` is ignored by newer migrations.
      columns: connection.columns(:ai_mcp_confirmations).map { |column| [column.name, column.sql_type.sub(%r{^timestamp\(\d\)}, 'timestamp'), column.null, column.default] },
      indexes: connection.indexes(:ai_mcp_confirmations).map { |index| [index.columns, index.unique] }.sort_by(&:to_s),
    }
  end

  context 'without the table, the setting and the scheduler' do
    before do
      Setting.find_by(name: 'api_mcp_access').destroy
      Scheduler.find_by(method: 'AI::MCPConfirmation.cleanup').destroy
    end

    it 'creates the table as on a fresh system, adds the switch of the MCP server to the API settings, off, and the daily cleanup' do
      fresh = schema
      drop_table :ai_mcp_confirmations

      migrate

      expect(schema).to eq(fresh)
      expect(Setting.find_by(name: 'api_mcp_access')).to have_attributes(
        area:          'API::Base',
        state_current: { 'value' => false },
        preferences:   include(permission: ['admin.api']),
        frontend:      false,
      )
      expect(Scheduler.find_by(method: 'AI::MCPConfirmation.cleanup')).to have_attributes(period: 1.day, active: true)
    end
  end

  context 'with the table, the setting and the scheduler' do
    before do
      Setting.set('api_mcp_access', true)
    end

    it 'keeps them as they are' do
      expect { migrate }.not_to change { [schema, Setting.get('api_mcp_access'), Scheduler.where(method: 'AI::MCPConfirmation.cleanup').pluck(:id)] }
    end
  end
end
