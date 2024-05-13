# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe PermissionSwitchToLabelDescription, db_strategy: :reset, type: :db_migration do
  let(:permission)      { Permission.find_by! name: permission_name }
  let(:permission_name) { 'admin' }

  before do
    ActiveRecord::Migration.rename_column(:permissions, :description, :note)
    ActiveRecord::Migration.remove_column(:permissions, :label)

    Permission.reset_column_information

    permission.preferences[:translations] = ['Sample']
    permission.preferences.delete(:prio)
    permission.save!(validate: false)
  end

  it 'updates attributes' do
    migrate

    expect(permission.reload).to have_attributes(
      label:       'Admin interface',
      description: 'Configure your system.',
      preferences: { prio: 1_000 }
    )
  end

  context 'when permission has additional preferences' do
    let(:permission_name) { 'user_preferences.overview_sorting' }

    it 'keeps additional preferences' do
      migrate

      expect(permission.reload).to have_attributes(
        preferences: { prio: 1690, required: ['ticket.agent'] }
      )
    end
  end
end
