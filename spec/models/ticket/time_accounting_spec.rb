# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Ticket::TimeAccounting, type: :model do
  subject(:time_accounting) { create(:'ticket/time_accounting') }

  describe 'Associations:' do
    describe '#ticket_article' do
      subject!(:time_accounting) { create(:'ticket/time_accounting', :for_article) }

      context 'when destroyed' do
        it 'destroys self' do
          expect { time_accounting.ticket_article.destroy }
            .to change(time_accounting, :persisted?).to(false)
            .and change(described_class, :count).by(-1)
        end

        it 'does not destroy other TimeAccountings for same ticket' do
          create(:'ticket/time_accounting', ticket: time_accounting.ticket)
          create(:'ticket/time_accounting', :for_article, ticket: time_accounting.ticket)

          expect { time_accounting.ticket_article.destroy }
            .to change(described_class, :count).by(-1)
        end
      end

      context 'when recalculating articles' do
        let(:ticket)   { create(:ticket) }
        let(:article1) { create(:ticket_article, ticket: ticket) }
        let(:article2) { create(:ticket_article, ticket: ticket) }

        it 'one article' do
          time_accounting = create(:'ticket/time_accounting', ticket: ticket, ticket_article: article1)

          expect(ticket.reload.time_unit).to eq(time_accounting.time_unit)
        end

        it 'multiple article' do
          time_accounting1 = create(:'ticket/time_accounting', ticket: ticket, ticket_article: article1, time_unit: 5.5)
          time_accounting2 = create(:'ticket/time_accounting', ticket: ticket, ticket_article: article2, time_unit: 10.5)

          expect(ticket.reload.time_unit).to eq(time_accounting1.time_unit + time_accounting2.time_unit)
        end

        it 'destroy article' do
          time_accounting1 = create(:'ticket/time_accounting', ticket: ticket, ticket_article: article1, time_unit: 5.5)
          create(:'ticket/time_accounting', ticket: ticket, ticket_article: article2, time_unit: 10.5)
          article2.destroy

          expect(ticket.reload.time_unit).to eq(time_accounting1.time_unit)
        end

        it 'destroy all articles' do
          create(:'ticket/time_accounting', ticket: ticket, ticket_article: article1, time_unit: 5.5)
          create(:'ticket/time_accounting', ticket: ticket, ticket_article: article2, time_unit: 10.5)
          article1.destroy
          article2.destroy

          expect(ticket.reload.time_unit).to eq(0)
        end
      end
    end
  end
end
