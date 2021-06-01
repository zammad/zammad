# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ForgetInsecureSessions, type: :db_migration do
  before do
    5.times do
      ActiveRecord::SessionStore::Session.create(
        session_id: SecureRandom.hex(16),
        data:       SecureRandom.base64(10)
      )
    end
  end

  context 'for HTTP deployment' do
    before { Setting.set('http_type', 'http') }

    it 'does not delete existing sessions' do
      expect { migrate }.not_to change(ActiveRecord::SessionStore::Session, :count)
    end
  end

  context 'for HTTPS deployment' do
    before { Setting.set('http_type', 'https') }

    it 'deletes all existing sessions' do
      expect { migrate }.to change(ActiveRecord::SessionStore::Session, :count).to(0)
    end
  end
end
