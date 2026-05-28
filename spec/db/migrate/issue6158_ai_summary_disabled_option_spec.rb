# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue6158AISummaryDisabledOption, db_strategy: :reset, type: :db_migration do
  before do
    attribute = ObjectManager::Attribute.get(object: 'Group', name: 'summary_generation')

    options = attribute.data_option['options'].reject { |option| option['value'] == 'disabled' }
    attribute.data_option['options'] = options
    attribute.save!
  end

  it 'adds the disabled option to the group summary generation attribute' do
    expect { migrate }
      .to change { ObjectManager::Attribute.get(object: 'Group', name: 'summary_generation').data_option['options'] }
      .to(include('name' => 'Hide ticket summary sidebar', 'value' => 'disabled'))
  end

  it 'is idempotent when the option is already present' do
    migrate
    expect { migrate }.not_to(change { ObjectManager::Attribute.get(object: 'Group', name: 'summary_generation').data_option['options'] })
  end
end
