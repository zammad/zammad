# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue3550SetPretty, type: :db_migration do
  context 'when cti gets migrated to stored pretty values' do
    let!(:cti) { create(:'cti/log') }

    before do
      # Bypass the model callback, which would store the pretty values on its own.
      cti.update_columns(preferences: {})
    end

    it 'has from_pretty' do
      expect { migrate }.to change { cti.reload.preferences[:from_pretty] }.from(nil).to('+49 30 609854180')
    end

    it 'has to_pretty' do
      expect { migrate }.to change { cti.reload.preferences[:to_pretty] }.from(nil).to('+49 30 609811111')
    end
  end
end
