# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ChangeTokenExpirationHandling, db_strategy: :reset, type: :db_migration do
  before do
    change_column :tokens, :expires_at, :date, null: true
    Token.reset_column_information
  end

  describe 'updating scheduler job' do
    let(:scheduler_job) { Scheduler.find_by(method: 'Token.cleanup') }

    before do
      scheduler_job.update! period: 30.days
    end

    it 'changes token cleanup period to 1 day' do
      expect { migrate }
        .to change { scheduler_job.reload.period }
        .to 1.day
    end
  end

  describe 'migrating expiration date column' do
    let(:token) { create(:token, expires_at:) }

    around do |example|
      tz = Setting.get('timezone_default')
      Setting.set('timezone_default', 'Asia/Tokyo')
      example.run
      Setting.set('timezone_default', tz)
    end

    context 'when token has expiration date' do
      let(:expires_at) { '2020-02-02'.to_date }

      it 'changes existing expiration dates to beginning-of-the-day' do
        expect { migrate }
          .to change { token.reload.expires_at }
          .to Time.zone.parse('2020-02-01 15:00')
      end
    end

    context 'when token has no expiration date' do
      let(:expires_at) { nil }

      it 'keeps token without expiration date' do
        expect { migrate }
          .not_to change { token.reload.expires_at }
      end
    end
  end
end
