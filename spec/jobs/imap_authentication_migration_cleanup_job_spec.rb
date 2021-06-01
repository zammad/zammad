# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ImapAuthenticationMigrationCleanupJob, type: :job do

  let(:migrated_at) { 8.days.ago }

  let(:channel) do
    channel = build(:channel, area: 'Google::Account')
    channel.options[:backup_imap_classic] = {
      backuphere:  1,
      migrated_at: migrated_at
    }
    channel.save!

    channel
  end

  it 'deletes obsolete classic IMAP backup' do
    expect { described_class.perform_now }.to change { channel.reload.options }
  end

  context 'recently migrated' do

    let(:migrated_at) { Time.zone.now }

    it 'keeps classic IMAP backup untouched' do
      expect { described_class.perform_now }.not_to change { channel.reload.options }
    end
  end
end
