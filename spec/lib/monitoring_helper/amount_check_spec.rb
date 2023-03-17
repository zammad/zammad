# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe MonitoringHelper::AmountCheck do
  let(:instance)   { described_class.new(params) }
  let(:ticket_now) { create(:ticket) }
  let(:ticket_10m) { travel_to(10.minutes.ago) { create(:ticket) } }
  let(:ticket_5d)  { travel_to(5.days.ago) { create(:ticket) } }
  let(:ticket_2w)  { travel_to(2.weeks.ago) { create(:ticket) } }
  let(:params)     { {} }

  before do
    Ticket.destroy_all
  end

  describe '#check_amount' do
    it 'raises error if no params given' do
      expect { instance.check_amount }.to raise_error %r{periode is missing}
    end

    context 'when period given' do
      let(:params) { { periode: '1w' } }

      it 'returns count if only period given' do
        allow(instance).to receive(:ticket_count).and_return(2)

        expect(instance.check_amount).to eq({ count: 2 })
      end
    end

    context 'when checks given' do
      let(:params) do
        {
          periode:     '1w',
          min_warning: 2
        }
      end

      it 'returns failure message if at least one check fails' do
        allow(instance).to receive(:ticket_count).and_return(1)
        expect(instance.check_amount)
          .to eq({ state: 'warning', message: 'The minimum of 2 was undercut by 1 in the last 1w', count: 1 })
      end

      it 'returns state and count if all checks pass' do
        allow(instance).to receive(:ticket_count).and_return(5)
        expect(instance.check_amount).to eq({ state: 'ok', count: 5 })
      end
    end
  end

  describe '#given_periode' do
    let(:params) { { periode: :test } }

    it 'returns period from params' do
      expect(instance.send(:given_periode)).to eq :test
    end
  end

  describe '#given_params' do
    it 'returns empty array if no params given' do
      expect(instance.send(:given_params)).to be_blank
    end

    context 'when valid params given' do
      let(:params) { { min_critical: 123 } }

      it 'returns passed params' do
        expect(instance.send(:given_params))
          .to eq([[{ notice: 'critical', param: :min_critical, type: 'lt' }, 123]])
      end
    end

    context 'when invalid params given' do
      let(:params) { { min_critical: 'abc' } }

      it 'raises error if param has non-integer value' do
        expect { instance.send(:given_params) }.to raise_error %r{needs to be an integer}
      end
    end
  end

  describe '#created_at_threshold' do
    before do
      freeze_time
    end

    it 'raises error if period missing' do
      expect { instance.send(:created_at_threshold) }.to raise_error %r{periode is missing}
    end

    it 'raises error if period is invalid' do
      instance.params[:periode] = '1z'
      expect { instance.send(:created_at_threshold) }.to raise_error %r{periode needs to have }
    end

    it 'raises error if period length is not included' do
      instance.params[:periode] = 'zd'
      expect { instance.send(:created_at_threshold) }.to raise_error %r{periode needs to be an integer}
    end

    it 'returns period in seconds' do
      instance.params[:periode] = '3s'
      expect(instance.send(:created_at_threshold)).to eq 3.seconds.ago
    end

    it 'returns period in minutes' do
      instance.params[:periode] = '1m'
      expect(instance.send(:created_at_threshold)).to eq 1.minute.ago
    end

    it 'returns period in hours' do
      instance.params[:periode] = '9h'
      expect(instance.send(:created_at_threshold)).to eq 9.hours.ago
    end

    it 'returns period in days' do
      instance.params[:periode] = '2d'
      expect(instance.send(:created_at_threshold)).to eq 2.days.ago
    end
  end

  describe '#ticket_count' do
    it 'returns ticket-count in given period' do
      ticket_10m && ticket_5d && ticket_2w

      allow(instance).to receive(:created_at_threshold).and_return(1.week.ago)
      expect(instance.send(:ticket_count)).to eq 2
    end
  end

  describe '#check_single_row' do
    let(:params) { { periode: '1w' } }

    before do
      allow(instance).to receive(:ticket_count).and_return(5)
    end

    context 'when checking if ticket count >= threshold' do
      let(:check) { { type: 'gt', notice: 'warning' } }

      it 'returns nil when check passes' do
        expect(instance.send(:check_single_row, check, 10)).to be_nil
      end

      it 'returns error when check fails' do
        expect(instance.send(:check_single_row, check, 4)).to include(state: 'warning', count: 5, message: match(%r{was exceeded with}))
      end
    end

    context 'when checking if ticket count <= threshold' do
      let(:check) { { type: 'lt', notice: 'critical' } }

      it 'returns nil when check passes' do
        expect(instance.send(:check_single_row, check, 4)).to be_nil
      end

      it 'returns error when check fails' do
        expect(instance.send(:check_single_row, check, 10)).to include(state: 'critical', count: 5, message: match(%r{was undercut by}))
      end
    end
  end
end
