# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue2608MissingTriggerPermission, type: :db_migration do
  let(:name) { 'admin.trigger' }

  context 'when "admin.trigger" permission already exists' do
    before { Permission.find_or_create_by(name: name) }

    it 'does nothing' do
      expect { migrate }.not_to change(Permission, :count)
    end
  end

  context 'when "admin.trigger" permission does not exist' do
    before { Permission.find_by(name: name)&.destroy }

    it 'creates it' do
      expect { migrate }
        .to change(Permission, :count).by(1)
        .and change { Permission.exists?(name: name) }.to(true)
    end
  end
end
