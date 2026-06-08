# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue5667ReservedWord, db_strategy: :reset, type: :db_migration do
  before do
    stub_const(
      'ObjectManager::Attribute::RESERVED_NAMES',
      ObjectManager::Attribute::RESERVED_NAMES.dup - ['data']
    )
    create(:object_manager_attribute_text, object_name: 'User', name: 'data')
    ObjectManager::Attribute.migration_execute
    stub_const(
      'ObjectManager::Attribute::RESERVED_NAMES',
      ObjectManager::Attribute::RESERVED_NAMES.dup << 'data'
    )
  end

  it 'does rename the reserved word data' do
    migrate
    expect(User.column_names.include?('_data')).to be(true)
  end
end
