# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue2401ConvertUserLoginEmailToUnicode, db_strategy: :reset, type: :db_migration do
  describe 'when user login/email has punycode formatted domain' do
    def create_user
      now = DateTime.now.strftime('%Y-%m-%d %H:%M:%S.000')
      ActiveRecord::Base.connection.execute(
        <<~SQL.squish
          INSERT INTO users (login, email, updated_by_id, created_by_id, created_at, updated_at)
          VALUES ('john.doe@xn--cme-pla.corp', 'john.doe@xn--cme-pla.corp', 1, 1, '#{now}', '#{now}')
        SQL
      )
      User.find_by(login: 'john.doe@xn--cme-pla.corp')
    end

    it 'converts login/email' do
      user = create_user

      expect { migrate }.to change { user.reload.login }
        .and change { user.reload.email }
        .and change { user.reload.updated_at }
    end

    it 'allows to lookup user with converted login/email' do
      create_user
      migrate

      expect(User).to be_exist(login: 'john.doe@äcme.corp')
        .and(be_exist(email: 'john.doe@äcme.corp'))

    end
  end

  describe 'when user login/email has unicode formatted domain' do
    let!(:user) { create(:user, login: 'john.doe@äcme.corp', email: 'john.doe@äcme.corp') }

    it 'does not convert login/email', :aggregate_failures do
      expect { migrate }.not_to change { user.reload.login }
      expect { migrate }.not_to change { user.reload.email }
      expect { migrate }.not_to change { user.reload.updated_at }
    end

    it 'still allows to lookup user with origin login/email', :aggregate_failures do
      migrate

      expect(User).to be_exist(login: 'john.doe@äcme.corp')
        .and(be_exist(email: 'john.doe@äcme.corp'))
    end

  end
end
