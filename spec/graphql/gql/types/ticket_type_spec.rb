# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

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

  describe 'field :shared_draft_zoom_id' do
    context 'when ticket has no shared draft' do
      let(:ticket) { create(:ticket) }

      it 'returns nil' do
        expect(instance.shared_draft_zoom_id).to be_nil
      end
    end

    context 'when ticket has a shared draft' do
      let(:ticket) do
        t = create(:ticket)
        s = create(:ticket_shared_draft_zoom, ticket: t)
        t.update(shared_draft: s)

        t
      end

      it 'returns the id' do
        expect(instance.shared_draft_zoom_id).to eq(Gql::ZammadSchema.id_from_object(ticket.shared_draft))
      end
    end
  end

  describe 'field :external_references :idoit' do
    context 'when ticket has a shared draft' do
      let(:ticket) { create(:ticket, preferences: { idoit: { object_ids: ['42'] } }) }

      context 'when idoit integration is inactive' do
        it 'returns the ids' do
          expect(instance.external_references).to be_nil
        end
      end

      context 'when idoit integration is active' do
        before do
          Setting.set('idoit_integration', true)
        end

        it 'returns the ids' do
          expect(instance.external_references[:idoit]).to eq([42])
        end
      end
    end
  end
end
