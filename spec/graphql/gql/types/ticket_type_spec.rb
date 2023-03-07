# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Types::TicketType do
  let(:instance) { described_class.send(:new, ticket, nil) }

  describe 'field :state_color_code' do

    context 'when ticket is open' do
      let(:ticket) { create(:ticket, escalation_at: escalation_at) }

      context 'without escalation' do
        let(:escalation_at) { nil }

        it "returns 'open'" do
          expect(instance.state_color_code).to eq('open')
        end
      end

      context 'with escalation' do
        let(:escalation_at) { 1.day.ago }

        it "returns 'escalating'" do
          expect(instance.state_color_code).to eq('escalating')
        end
      end
    end

    context 'when ticket is pending' do
      let(:ticket) { create(:ticket, state: Ticket::State.find_by(name: 'pending reminder'), pending_time: pending_time) }

      context 'with pending time in future' do
        let(:pending_time) { 1.day.from_now }

        it "returns 'pending'" do
          expect(instance.state_color_code).to eq('pending')
        end
      end

      context 'with pending time in past' do
        let(:pending_time) { 1.day.ago }

        it "returns 'open'" do
          expect(instance.state_color_code).to eq('open')
        end
      end
    end

    context 'when ticket is closed' do
      let(:ticket) { create(:ticket, state: Ticket::State.find_by(name: 'closed')) }

      it "returns 'closed'" do
        expect(instance.state_color_code).to eq('closed')
      end
    end
  end
end
