# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/application_model_examples'
require 'models/sla/has_escalation_calculation_impact_examples'

RSpec.describe Sla, type: :model do
  it_behaves_like 'ApplicationModel', can_assets: { associations: :calendar, selectors: :condition }
  it_behaves_like 'HasEscalationCalculationImpact'

  context 'when matching Ticket' do

    let(:sla)       { create(:sla, :condition_title, condition_title: 'matching') }
    let(:sla_blank) { create(:sla, :condition_blank) }

    let(:ticket_matching)     { create(:ticket, title: 'matching title') }
    let(:ticket_not_matching) { create(:ticket, title: 'nope') }

    describe '#condition_matches?' do
      it 'returns true when condition matches ticket' do
        expect(sla).to be_condition_matches(ticket_matching)
      end

      it 'returns false when condition does not match ticket' do
        expect(sla).not_to be_condition_matches(ticket_not_matching)
      end

      it 'returns false when condition does not match ticket while matching tickets exist' do
        ticket_matching
        expect(sla).not_to be_condition_matches(ticket_not_matching)
      end

      it 'returns true when SLA condition is blank ticket' do
        expect(sla_blank).to be_condition_matches(ticket_not_matching)
      end
    end

    describe '#cannot_have_response_and_update' do
      it 'allows neither #response_time nor #update_time' do
        instance = build(:sla, response_time: nil, update_time: nil)
        expect(instance).to be_valid
      end

      it 'allows #response_time' do
        instance = build(:sla, response_time: 180, update_time: nil)
        expect(instance).to be_valid
      end

      it 'allows #update_time' do
        instance = build(:sla, response_time: nil, update_time: 180)
        expect(instance).to be_valid
      end

      it 'denies both #response_time and #update_time' do
        instance = build(:sla, response_time: 180, update_time: 180)
        expect(instance).not_to be_valid
      end
    end

    describe '.for_ticket' do
      it 'returns matching SLA for the ticket' do
        sla
        expect(described_class.for_ticket(ticket_matching)).to eq sla
      end

      it 'returns nil when no SLA matches ticket' do
        sla
        expect(described_class.for_ticket(ticket_not_matching)).to be_nil
      end

      it 'returns blank SLA for the ticket' do
        sla_blank
        expect(described_class.for_ticket(ticket_matching)).to eq sla_blank
      end

      it 'returns non-blank SLA over blank SLA for the ticket' do
        sla
        sla_blank
        expect(described_class.for_ticket(ticket_matching)).to eq sla
      end

      context 'when multiple SLAs are matching' do
        let(:sla) { create(:sla, :condition_title, condition_title: 'matching', name: 'ZZZ 1') }
        let(:sla2) { create(:sla, :condition_title, condition_title: 'matching', name: 'AAA 1') }

        before do
          sla
          sla2
        end

        it 'returns the AAA 1 sla as matching' do
          expect(described_class.for_ticket(ticket_matching)).to eq sla2
        end
      end
    end
  end
end
