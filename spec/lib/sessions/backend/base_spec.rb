# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sessions::Backend::Base do
  subject(:backend) { described_class.new(agent, {}, false, client_id, ttl) }

  let(:agent) { create(:agent) }
  let(:client_id) { '123-1' }
  let(:ttl) { 3 } # seconds
  let!(:ticket) { Ticket.first || create(:ticket) }

  describe '#asset_needed?' do
    context 'before #asset_push has ever been called for the given record' do
      it 'returns true' do
        expect(backend.asset_needed?(ticket)).to be(true)
      end
    end

    context 'when #asset_push was previously called for the given record' do
      before { backend.asset_push(ticket, {}) }

      it 'returns false' do
        expect(backend.asset_needed?(ticket)).to be(false)
      end

      context 'within two hours of the backend’s #time_now value' do
        before { backend.time_now = (2.hours - 1.second).from_now.to_i }

        it 'returns false' do
          expect(backend.asset_needed?(ticket)).to be(false)
        end
      end

      context 'over two hours before the backend’s #time_now value' do
        before { backend.time_now = (2.hours + 1.second).from_now.to_i }

        it 'returns true' do
          expect(backend.asset_needed?(ticket)).to be(true)
        end
      end

      context 'prior to the record’s last update' do
        before { ticket.touch }

        it 'returns true' do
          expect(backend.asset_needed?(ticket)).to be(true)
        end
      end
    end
  end

  describe '#asset_needed_by_updated_at?' do
    let(:method_args) { [ticket.class.name, ticket.id, ticket.updated_at] }

    context 'before #asset_push has ever been called for the given record' do
      it 'returns true' do
        expect(backend.asset_needed_by_updated_at?(*method_args)).to be(true)
      end
    end

    context 'when #asset_push was previously called for the given record' do
      before { backend.asset_push(ticket, {}) }

      it 'returns false' do
        expect(backend.asset_needed_by_updated_at?(*method_args)).to be(false)
      end

      context 'within two hours of the backend’s #time_now value' do
        before { backend.time_now = (2.hours - 1.second).from_now.to_i }

        it 'returns false' do
          expect(backend.asset_needed_by_updated_at?(*method_args)).to be(false)
        end
      end

      context 'over two hours before the backend’s #time_now value' do
        before { backend.time_now = (2.hours + 1.second).from_now.to_i }

        it 'returns true' do
          expect(backend.asset_needed_by_updated_at?(*method_args)).to be(true)
        end
      end

      context 'prior to the record’s last update' do
        before { ticket.touch }

        it 'returns true' do
          expect(backend.asset_needed_by_updated_at?(*method_args)).to be(true)
        end
      end
    end
  end

  describe '#asset_push' do
    it 'returns the assets for the given record' do
      expect(backend.asset_push(ticket, {})).to eq(ticket.assets({}))
    end
  end
end
