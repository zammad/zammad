# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AddChecklists, db_strategy: :reset, type: :db_migration do
  before do
    remove_reference :tickets, :checklist

    %i[checklist_template_items checklist_templates checklist_items checklists].each do |table|
      drop_table table
    end

    Setting.find_by(name: 'checklist')&.destroy
    Permission.find_by(name: 'admin.checklist')&.destroy

    migrate
  end

  it 'adds setting' do
    expect(Setting).to exist(name: 'checklist')
  end

  it 'adds permission' do
    expect(Permission).to exist(name: 'admin.checklist')
  end

  it 'creates tables' do
    expect(tables).to include('checklist_templates', 'checklist_template_items', 'checklists', 'checklist_items')
  end
end
