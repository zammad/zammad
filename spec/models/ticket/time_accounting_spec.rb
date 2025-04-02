# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

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

        it 'destroy time accounting' do
          time_accounting1 = create(:'ticket/time_accounting', ticket: ticket, ticket_article: article1, time_unit: 5.5)
          time_accounting2 = create(:'ticket/time_accounting', ticket: ticket, ticket_article: article2, time_unit: 10.5)

          expect { time_accounting2.destroy }
            .to change { ticket.reload.time_unit }
            .to time_accounting1.time_unit
        end

        it 'update time accounting' do
          new_time_unit = 99

          time_accounting = create(:'ticket/time_accounting', ticket: ticket, ticket_article: article1, time_unit: 5.5)

          expect { time_accounting.update! time_unit: new_time_unit }
            .to change { ticket.reload.time_unit }
            .to new_time_unit
        end

        it 'destroy all articles' do
          create(:'ticket/time_accounting', ticket: ticket, ticket_article: article1, time_unit: 5.5)
          create(:'ticket/time_accounting', ticket: ticket, ticket_article: article2, time_unit: 10.5)
          article1.destroy
          article2.destroy

          expect(ticket.reload.time_unit).to eq(0)
        end
      end

      context 'when using time accounting type' do
        subject!(:time_accounting) { create(:'ticket/time_accounting', :for_article, type: type) }

        let(:type) { nil }

        context 'without a type' do
          it 'does not have a type' do
            expect(time_accounting.type).to be_nil
          end
        end

        context 'with a type' do
          let(:type) { create(:ticket_time_accounting_type) }

          it 'does not have a type' do
            expect(time_accounting.type.name).to eq(type.name)
          end

          it 'can edit a time accounting type' do
            other_type = create(:ticket_time_accounting_type)
            time_accounting.update!(type: other_type)

            expect(time_accounting.reload.type.name).to eq(other_type.name)
          end

          it 'can remove time accounting type' do
            time_accounting.update!(type: nil)

            expect(time_accounting.reload.type).to be_nil
          end
        end
      end
    end
  end

  describe 'validation' do
    describe 'article uniqueness' do
      let(:ticket)  { create(:ticket) }
      let(:article) { create(:ticket_article, ticket: ticket) }

      before do
        create(:ticket_time_accounting, ticket: ticket, ticket_article: article)
      end

      it 'allows multiple ticket article items per ticket' do
        another_article = create(:ticket_article, ticket: ticket)
        item            = create(:ticket_time_accounting, ticket: ticket, ticket_article: another_article)

        expect(item).to be_persisted
      end

      it 'allows multiple article-less items per ticket' do
        expect(create_list(:ticket_time_accounting, 2, ticket: ticket)).to all(be_persisted)
      end

      it 'does not allow multiple articles for same ticket' do
        item = build(:ticket_time_accounting, ticket: ticket, ticket_article: article)

        expect(item).not_to be_valid
      end
    end

    describe 'ticket article has to be part of the same ticket' do
      let(:ticket)                    { create(:ticket) }
      let(:article)                   { create(:ticket_article, ticket: ticket) }
      let(:article_in_another_ticket) { create(:ticket_article) }

      it 'allows article matching ticket' do
        time_accounting = build(:ticket_time_accounting, ticket: ticket, ticket_article: article)
        expect(time_accounting).to be_valid
      end

      it 'does not allow article from another ticket' do
        time_accounting = build(:ticket_time_accounting, ticket: ticket, ticket_article: article_in_another_ticket)
        expect(time_accounting).not_to be_valid
      end
    end
  end
end
