# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue3550SetPretty, db_strategy: :reset, type: :db_migration do
  context 'when cti gets migrated to stored pretty values' do
    let!(:cti) { create(:'cti/log') }

    before do
      migrate
    end

    it 'has from_pretty' do
      expect(cti.preferences[:from_pretty]).to eq('+49 30 609854180')
    end

    it 'has to_pretty' do
      expect(cti.preferences[:to_pretty]).to eq('+49 30 609811111')
    end
  end
end
