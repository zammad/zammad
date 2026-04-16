# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Ticket::Bulk::SingleItemUpdate do
  let(:group)    { create(:group) }
  let(:user)     { create(:agent, groups: [group]) }
  let(:ticket)   { create(:ticket, group:) }
  let(:perform)  { { input: { title: 'new title' } } }
  let(:instance) { described_class.new(user:, ticket:, perform:) }

  describe '#execute' do
    it 'executes ticket update service' do
      expect { instance.execute }
        .to change { ticket.reload.title }
        .to('new title')
    end

    it 'uses passed user as the current user' do
      instance.execute

      expect(ticket.reload.updated_by_id).to eq(user.id)
    end

    context 'when perform input is nil' do
      let(:perform) { { input: nil } }

      it 'does not update the ticket' do
        expect { instance.execute }
          .not_to change { ticket.reload.title }
      end
    end

    context 'when perform input is empty' do
      let(:perform) { { input: {} } }

      it 'does not update the ticket' do
        expect { instance.execute }
          .not_to change { ticket.reload.title }
      end
    end

    context 'when user does not have agent write access to the ticket' do
      let(:ticket) { create(:ticket) }

      it 'raises an error', aggregate_failures: true do
        expect { instance.execute }
          .to raise_error do |error|
            expect(error).to be_a described_class::BulkSingleError
            expect(error.record).to eq(ticket)
            expect(error.original_error).to be_a Pundit::NotAuthorizedError
          end
      end
    end

    context 'when update results in validation error' do
      before do
        allow(ticket)
          .to receive(:save!)
          .and_raise(ActiveRecord::RecordInvalid.new(ticket))
      end

      it 'raises an error', aggregate_failures: true do
        expect { instance.execute }
          .to raise_error do |error|
            expect(error).to be_a described_class::BulkSingleError
            expect(error.record).to eq(ticket)
            expect(error.original_error).to be_a ActiveRecord::RecordInvalid
          end
      end
    end

    context 'when update results in a generic error' do
      before do
        allow(ticket)
          .to receive(:save!)
          .and_raise(StandardError.new('some error'))
      end

      it 'raises an error', aggregate_failures: true do
        expect { instance.execute }
          .to raise_error do |error|
            expect(error).to be_a described_class::BulkSingleError
            expect(error.record).to eq(ticket)
            expect(error.original_error).to be_a StandardError
          end
      end
    end
  end
end
