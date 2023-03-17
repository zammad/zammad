# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue3851, type: :db_migration do
  let(:follow_up_assignment) { ObjectManager::Attribute.for_object('Group').find_by(name: 'follow_up_assignment') }
  let(:follow_up_possible)   { ObjectManager::Attribute.for_object('Group').find_by(name: 'follow_up_possible') }

  before do
    migrate
  end

  it 'shows field follow_up_assignment with correct default' do
    expect(follow_up_assignment.data_option['default']).to eq('true')
  end

  it 'shows field follow_up_assignment required in create' do
    expect(follow_up_assignment.screens['create']['-all-']['null']).to be(false)
  end

  it 'shows field follow_up_assignment required in edit' do
    expect(follow_up_assignment.screens['edit']['-all-']['null']).to be(false)
  end

  it 'shows field follow_up_possible required in create' do
    expect(follow_up_possible.screens['create']['-all-']['null']).to be(false)
  end

  it 'shows field follow_up_possible required in edit' do
    expect(follow_up_possible.screens['edit']['-all-']['null']).to be(false)
  end
end
