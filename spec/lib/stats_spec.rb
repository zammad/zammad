# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Stats do

  describe '#generate' do

    before do
      # create a user for which the stats can be generated
      create(:agent)
    end

    it 'generates stats' do
      expect { described_class.generate }.not_to raise_error
    end

    context 'when the dashboard and a stats widget are turned off' do
      let(:agent) { create(:agent) }

      before do
        Setting.set('dashboard', false)
        Setting.set('dashboard_stats_ticket_waiting_time', false)
        agent
      end

      it 'keeps generating the stats, so they are current once turned on again' do
        described_class.generate

        data = StatsStore.find_by(stats_storable: agent, key: 'dashboard').data
        expect(data).to have_key('StatsTicketWaitingTime')
      end
    end

    context 'when backend registration is invalid' do

      it 'fails for empty registration' do
        Setting.set('Stats::TicketWaitingTime', nil)
        expect { described_class.generate }.to raise_error(RuntimeError)
      end

      it 'fails for unknown backend' do
        Setting.set('Stats::TicketWaitingTime', 'Stats::UNKNOWN')
        expect { described_class.generate }.to raise_error(NameError)
      end
    end
  end
end
