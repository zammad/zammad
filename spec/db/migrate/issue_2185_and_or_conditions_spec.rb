# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue2185AndOrConditions, type: :db_migration do
  before do
    %w[ticket_hook ticket_hook_position ticket_last_contact_behaviour].each do |name|
      setting = Setting.find_by(name: name)
      setting[:preferences].delete(:prio)
      setting.save
    end
    Setting.find_by(name: 'ticket_allow_expert_conditions').destroy!

    migrate
  end

  it 'migrates prio of ticket_hook setting' do
    expect(Setting.find_by(name: 'ticket_hook')[:preferences][:prio]).to eq(1000)
  end

  it 'migrates prio of ticket_hook_position setting' do
    expect(Setting.find_by(name: 'ticket_hook_position')[:preferences][:prio]).to eq(2000)
  end

  it 'migrates prio of ticket_last_contact_behaviour setting' do
    expect(Setting.find_by(name: 'ticket_last_contact_behaviour')[:preferences][:prio]).to eq(3000)
  end

  it 'creates ticket_allow_expert_conditions setting' do
    expect(Setting.find_by(name: 'ticket_allow_expert_conditions')).not_to be_nil
  end
end
