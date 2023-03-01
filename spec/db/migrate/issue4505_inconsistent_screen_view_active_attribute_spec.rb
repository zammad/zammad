# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue4505InconsistentScreenViewActiveAttribute, type: :db_migration do
  context 'when it has wrong active screen value', db_strategy: :reset do
    let(:attribute) { ObjectManager::Attribute.get(name: 'active', object: 'Organization') }

    before do
      attribute.screens[:view][:'ticket.agent'][:shown] = true
      attribute.save!
    end

    it 'does set the correct active screen value' do
      expect { migrate }.to change { attribute.reload.screens[:view][:'ticket.agent'][:shown] }.from(true).to(false)
    end
  end
end
