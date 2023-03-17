# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ObjectManagerUpdateUserPassword, type: :db_migration do
  let(:attr) do
    object_type = ObjectLookup.find_by(name: 'User')
    ObjectManager::Attribute.find_by object_lookup_id: object_type.id, name: 'password'
  end

  before do
    attr.data_option['maxlength'] = 123
    attr.save!
  end

  it 'changes maxlength' do
    expect { migrate }.to change { attr.reload.data_option[:maxlength] }.from(123).to(1001)
  end
end
