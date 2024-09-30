# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Ticket::Update::Validator::ChecklistCompleted, current_user_id: 1 do
  subject(:validator) { described_class.new(user: user, ticket: ticket, ticket_data: ticket_data, article_data: article_data) }

  let(:user)          { create(:agent, groups: [group]) }
  let(:ticket)        { create(:ticket) }
  let(:group)         { ticket.group }
  let(:new_title)     { Faker::Lorem.unique.word }
  let(:ticket_data)   { { title: new_title } }
  let(:article_data)  { nil }

  shared_examples 'not raising an error' do
    it 'does not raise an error' do
      expect { validator.valid! }.not_to raise_error
    end
  end

  shared_examples 'raising an error' do
    it 'raises an error' do
      expect { validator.valid! }.to raise_error(Service::Ticket::Update::Validator::ChecklistCompleted::Error, 'The ticket checklist is incomplete.')
    end
  end

  describe '#valid!' do
    it_behaves_like 'not raising an error'

    context 'when ticket has a checklist' do
      let(:checklist) { create(:checklist, ticket: ticket) }

      before do
        checklist
      end

      context 'when ticket is being closed' do
        let(:ticket_data) { { state: Ticket::State.find_by(name: 'closed') } }

        it_behaves_like 'raising an error'

        context 'when checklist is complete' do
          let(:checklist) do
            create(:checklist, ticket: ticket).tap do |checklist|
              checklist.items.each { |item| item.update!(checked: true) }
            end
          end

          it_behaves_like 'not raising an error'
        end
      end

      context 'when ticket is being auto-closed' do
        let(:ticket_data) { { state: Ticket::State.find_by(name: 'pending close') } }

        it_behaves_like 'raising an error'
      end

      context 'when ticket is not being closed' do
        let(:ticket_data) { { state: Ticket::State.find_by(name: 'open') } }

        it_behaves_like 'not raising an error'
      end
    end
  end
end
