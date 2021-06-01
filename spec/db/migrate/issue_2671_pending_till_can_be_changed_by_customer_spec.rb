# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue2671PendingTillCanBeChangedByCustomer, type: :db_migration do
  let(:attr) { ObjectManager::Attribute.find_by name: :pending_time }
  let(:initial_data_option) { { future: true, past: true, diff: 0 } }

  before do
    attr.update!(data_option: initial_data_option)
  end

  it 'adds permission' do
    migrate
    expect(attr.reload.data_option).to include(permission: %w[ticket.agent])
  end

  it 'keeps other settings' do
    migrate
    expect(attr.reload.data_option).to include(initial_data_option)
  end
end
