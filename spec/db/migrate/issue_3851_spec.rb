# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue3851, type: :db_migration do
  let(:follow_up_assignment) { ObjectManager::Attribute.for_object('Group').find_by(name: 'follow_up_assignment') }
  let(:follow_up_possible)   { ObjectManager::Attribute.for_object('Group').find_by(name: 'follow_up_possible') }

  before do
    follow_up_assignment.data_option['default'] = 'false'
    [follow_up_assignment, follow_up_possible].each do |attribute|
      attribute.screens['create']['-all-']['null'] = true
      attribute.screens['edit']['-all-']['null']   = true
      attribute.save!
    end
  end

  it 'shows field follow_up_assignment with correct default' do
    expect { migrate }.to change { follow_up_assignment.reload.data_option['default'] }.from('false').to('true')
  end

  it 'shows field follow_up_assignment required in create' do
    expect { migrate }.to change { follow_up_assignment.reload.screens['create']['-all-']['null'] }.from(true).to(false)
  end

  it 'shows field follow_up_assignment required in edit' do
    expect { migrate }.to change { follow_up_assignment.reload.screens['edit']['-all-']['null'] }.from(true).to(false)
  end

  it 'shows field follow_up_possible required in create' do
    expect { migrate }.to change { follow_up_possible.reload.screens['create']['-all-']['null'] }.from(true).to(false)
  end

  it 'shows field follow_up_possible required in edit' do
    expect { migrate }.to change { follow_up_possible.reload.screens['edit']['-all-']['null'] }.from(true).to(false)
  end
end
