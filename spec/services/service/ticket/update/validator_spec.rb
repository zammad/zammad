# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Ticket::Update::Validator do
  subject(:validator) { described_class.new(user: user, ticket: ticket, ticket_data: ticket_data, article_data: article_data, skip_validator: skip_validator) }

  let(:user)           { create(:agent, groups: [group]) }
  let(:ticket)         { create(:ticket) }
  let(:group)          { ticket.group }
  let(:new_title)      { Faker::Lorem.unique.word }
  let(:ticket_data)    { { title: new_title } }
  let(:article_data)   { nil }
  let(:skip_validator) { nil }

  describe '#validate!' do
    it 'does not raise an error' do
      expect { validator.validate! }.not_to raise_error
    end

    context 'when ticket with a checklist is being closed' do
      let(:checklist)   { create(:checklist, ticket: ticket) }
      let(:ticket_data) { { state: Ticket::State.find_by(name: 'closed') } }

      before do
        checklist
      end

      it 'raises an error' do
        expect { validator.validate! }.to raise_error(Service::Ticket::Update::Validator::ChecklistCompleted::IncompleteChecklistError)
      end

      context 'when validator is being skipped' do
        let(:skip_validator) { 'Service::Ticket::Update::Validator::ChecklistCompleted::IncompleteChecklistError' }

        it 'does not raise an error' do
          expect { validator.validate! }.not_to raise_error
        end
      end
    end
  end
end
