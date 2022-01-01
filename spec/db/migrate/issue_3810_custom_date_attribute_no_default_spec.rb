# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue3810CustomDateAttributeNoDefault, type: :db_migration, db_strategy: :reset_all do
  before :all do # rubocop:disable RSpec/BeforeAfterAll
    create('object_manager_attribute_date', name: 'rspec_date', default: 24)
    create('object_manager_attribute_datetime', name: 'rspec_datetime', default: 24)

    ObjectManager::Attribute.migration_execute
  end

  after :all do # rubocop:disable RSpec/BeforeAfterAll
    ObjectManager::Attribute.where('name LIKE ?', 'rspec_%').destroy_all
  end

  it 'unsets diff migration' do
    migrate
    expect(create(:ticket)).to have_attributes(rspec_date: nil, rspec_datetime: nil)
  end
end
