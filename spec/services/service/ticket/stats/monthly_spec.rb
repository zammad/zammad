# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Ticket::Stats::Monthly, :aggregate_failures do
  subject(:service_result) { described_class.with_current_user(user).execute(conditions:) }

  let(:group)      { create(:group) }
  let(:user)       { create(:agent, groups: [group]) }
  let(:conditions) { {} }

  describe '#execute' do
    before do
      freeze_time
    end

    context 'with tickets in current month' do
      let!(:ticket_created) { create(:ticket, group: group, created_at: Time.zone.now) }
      let!(:ticket_closed)  { create(:ticket, group: group, created_at: 1.month.ago, close_at: Time.zone.now) }

      before { ticket_created && ticket_closed }

      it 'returns 12 months of data' do
        expect(service_result).to be_an(Array)
        expect(service_result.size).to eq(12)
      end

      it 'includes correct keys in each month' do
        expect(service_result.first.keys).to contain_exactly(:year, :month_number, :month_label, :tickets_created, :tickets_closed)
      end

      it 'counts tickets created in current month' do
        expect(service_result.first[:tickets_created]).to eq(1)
      end

      it 'counts tickets closed in current month' do
        expect(service_result.first[:tickets_closed]).to eq(1)
      end

      it 'includes correct month information' do
        current_month = service_result.first
        now = Time.zone.now

        expect(current_month[:year]).to eq(now.year)
        expect(current_month[:month_number]).to eq(now.month)
        expect(current_month[:month_label]).to eq(Date::ABBR_MONTHNAMES[now.month])
      end
    end

    context 'with additional conditions' do
      subject(:service_result) { described_class.with_current_user(user).execute(conditions: { state_id: Ticket::State.find_by(name: 'open').id }) }

      let!(:open_ticket)   { create(:ticket, group: group, state: Ticket::State.find_by(name: 'open'), created_at: Time.zone.now) }
      let!(:closed_ticket) { create(:ticket, group: group, state: Ticket::State.find_by(name: 'closed'), created_at: Time.zone.now) }

      before { open_ticket && closed_ticket }

      it 'filters tickets by conditions' do
        expect(service_result.first[:tickets_created]).to eq(1)
      end
    end

    context 'with tickets across multiple months' do
      let!(:ticket_this_month)  { create(:ticket, group: group, created_at: Time.zone.now) }
      let!(:ticket_last_month)  { create(:ticket, group: group, created_at: 1.month.ago) }
      let!(:ticket_two_months)  { create(:ticket, group: group, created_at: 2.months.ago) }

      before { ticket_this_month && ticket_last_month && ticket_two_months }

      it 'distributes tickets correctly across months' do
        expect(service_result[0][:tickets_created]).to eq(1)  # current month
        expect(service_result[1][:tickets_created]).to eq(1)  # last month
        expect(service_result[2][:tickets_created]).to eq(1)  # two months ago
        expect(service_result[3][:tickets_created]).to eq(0)  # three months ago
      end
    end

    context 'when user has no read access' do
      let(:other_group) { create(:group) }
      let!(:ticket)     { create(:ticket, group: other_group, created_at: Time.zone.now) }

      before { ticket }

      it 'does not count tickets from inaccessible groups' do
        expect(service_result.first[:tickets_created]).to eq(0)
      end
    end

    # https://github.com/zammad/zammad/issues/5865
    context 'when the ticket is created just before the new month' do
      let(:ticket) { create(:ticket, group: group, created_at: Time.zone.parse('2019-06-30 23:00')) }

      before do
        ticket
        Setting.set('timezone_default', timezone)
        travel_to Time.zone.parse('2019-07-02 01:00')
      end

      context 'when time zome is ahead of UTC' do
        let(:timezone) { 'Asia/Tokyo' }

        it 'returns tickets according to Zammad time zone' do
          expect(service_result.first[:tickets_created]).to eq(1)
          expect(service_result.second[:tickets_created]).to eq(0)
        end
      end

      context 'when time zone is behind UTC' do
        let(:timezone) { 'America/New_York' }

        it 'returns tickets according to Zammad time zone' do
          expect(service_result.first[:tickets_created]).to eq(0)
          expect(service_result.second[:tickets_created]).to eq(1)
        end
      end
    end
  end
end
