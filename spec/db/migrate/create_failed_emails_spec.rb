# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe CreateFailedEmails, db_strategy: :reset, type: :db_migration do
  before do
    ActiveRecord::Migration[7.0].drop_table :failed_emails
    # make sure folder does not exist
    FileUtils.rm_rf(dir)
  end

  describe '#up', system_init_done: true do
    let(:dir) { described_class::OLD_FAILED_EMAIL_DIRECTORY }

    context 'when unprocessable email files exist' do
      let(:content) { attributes_for(:failed_email)[:data] }

      before do
        FileUtils.mkdir_p dir

        File.binwrite dir.join('test.eml'), content
      end

      it 'imports unprocessable email form files' do
        migrate

        expect(FailedEmail.first).to have_attributes(data: content)
      end

      it 'removes unprocessable email directory' do
        expect { migrate }
          .to change { Dir.exist? dir }
          .to false
      end
    end

    context 'when unprocessable emails directory does not exist' do
      it 'does not crash' do
        expect { migrate }.not_to raise_error
      end
    end
  end
end
