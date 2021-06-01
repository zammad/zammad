# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Unit::Import::Ldap::Users::Lost::Deactivate, sequencer: :unit do
  let!(:lost_users) { create_list(:user, sample_length, attributes) }
  let(:sample_length) { 2 }

  context 'when provided ids of active users' do
    let(:attributes) { { active: true } }

    it 'deactivates them' do
      expect { process(lost_ids: lost_users.pluck(:id), dry_run: false) }
        .to change { lost_users.each(&:reload).pluck(:active) }.to(Array.new(sample_length, false))
    end
  end

  context 'when provided ids of users with any `updated_by_id`' do
    # ordinarily, a History log's created_by_id is based on this value (or UserInfo.current_user_id),
    # but this Sequencer unit is expected to override it
    let(:attributes) { { updated_by_id: 2 } }

    it 'enforces created_by_id => 1 in newly created History logs' do
      expect { process(lost_ids: lost_users.pluck(:id), dry_run: false) }
        .to change(History, :count).by(sample_length)

      expect(History.last(sample_length).pluck(:created_by_id))
        .to eq(Array.new(sample_length, 1))
    end
  end
end
