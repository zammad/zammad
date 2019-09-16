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
    end
  end
end
