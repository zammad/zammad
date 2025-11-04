# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe TicketSummaryGeneration, db_strategy: :reset, type: :db_migration do
  before do
    CoreWorkflow
      .find_by(name: 'base - show summary generation')
      &.destroy

    ObjectManager::Attribute
      .find_by(object_lookup: ObjectLookup.find_by(name: 'Group'), name: 'summary_generation')
      &.destroy

    remove_column :groups, :summary_generation
    Group.reset_column_information
  end

  it 'extends ticket summary config' do
    Setting.set('ai_assistance_ticket_summary_config', { a: true, b: false })

    migrate

    expect(Setting.get('ai_assistance_ticket_summary_config')).to include(
      a:           true,
      b:           false,
      generate_on: 'on_ticket_detail_opening'
    )
  end

  it 'extends group table' do
    group = create(:group)

    migrate

    expect(group.reload).to have_attributes(summary_generation: 'global_default')
  end
end
