# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AddChecklists, db_strategy: :reset, type: :db_migration do
  before do
    %i[checklist_template_items checklist_templates checklist_items checklists].each do |table|
      ActiveRecord::Migration[5.0].drop_table table
    end

    Setting.find_by(name: 'checklist')&.destroy

    Permission.find_by(name: 'admin.checklist')&.destroy

    migrate
  end

  it 'adds setting' do
    expect(Setting.find_by(name: 'checklist')).to be_present
  end

  it 'adds permission' do
    expect(Permission.find_by(name: 'admin.checklist')).to be_present
  end

  it 'creates checklist_templates table' do
    expect(table_exists?(:checklist_templates)).to be(true)
  end

  it 'creates checklist_template_items table' do
    expect(table_exists?(:checklist_template_items)).to be(true)
  end

  it 'creates checklists table' do
    expect(table_exists?(:checklists)).to be(true)
  end

  it 'creates checklist_items table' do
    expect(table_exists?(:checklist_items)).to be(true)
  end
end
