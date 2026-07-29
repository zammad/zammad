# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe RefactorRecentViewsUpsert, db_strategy: :reset, type: :db_migration do
  before do
    without_index(:recent_views, column: %i[o_id recent_view_object_id created_by_id])
    without_index(:recent_views, column: :updated_at)
  end

  context 'when duplicate recent view entries exist' do
    let(:user)             { create(:agent) }
    let(:other_user)       { create(:agent) }
    let(:ticket)           { create(:ticket) }
    let(:ticket_object_id) { ObjectLookup.by_name('Ticket') }

    let!(:latest_view) do
      create(:recent_view, o: ticket, created_by_id: user.id, created_at: 1.minute.ago, updated_at: 1.minute.ago)
    end

    let!(:other_user_view) do
      create(:recent_view, o: ticket, created_by_id: other_user.id)
    end

    before do
      # Older duplicates of the same (o_id, recent_view_object_id, created_by_id) tuple,
      # bypassing the (temporarily removed) unique index.
      [2.hours.ago, 1.hour.ago].each do |timestamp|
        build(:recent_view, o: ticket, created_by_id: user.id, created_at: timestamp, updated_at: timestamp)
          .save!(validate: false)
      end
    end

    it 'collapses duplicates to a single entry per object and user' do
      expect { migrate }.to change(RecentView, :count).by(-2)
    end

    it 'keeps exactly one entry for the affected tuple' do
      migrate

      expect(RecentView.where(o_id: ticket.id, recent_view_object_id: ticket_object_id, created_by_id: user.id).count)
        .to eq(1)
    end

    it 'carries over the most recent view time to the surviving entry' do
      migrate

      surviving = RecentView.find_by(o_id: ticket.id, recent_view_object_id: ticket_object_id, created_by_id: user.id)
      expect(surviving.updated_at).to be_within(1.second).of(latest_view.created_at)
    end

    it 'leaves entries of other users untouched' do
      expect { migrate }.not_to change { RecentView.exists?(other_user_view.id) }.from(true)
    end

    it 'adds a unique index preventing further duplicates' do
      migrate

      expect { build(:recent_view, o: ticket, created_by_id: user.id).save!(validate: false) }
        .to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
