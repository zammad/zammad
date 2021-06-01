# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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
    end
  end
end
