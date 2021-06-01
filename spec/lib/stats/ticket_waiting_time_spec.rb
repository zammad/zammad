# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Stats::TicketWaitingTime do
  describe '.generate' do
    let(:user) { create(:agent, groups: [group]) }
    let(:group) { create(:group) }

    context 'when given an agent with no tickets' do
      it 'returns a hash with 1-day average ticket wait time for user (in minutes)' do
        expect(described_class.generate(user)).to include(handling_time: 0)
      end

      it 'returns a hash with 1-day average ticket wait time across user’s groups (in minutes)' do
        expect(described_class.generate(user)).to include(average_per_agent: 0)
      end

      it 'returns a hash with verbal grade for average ticket wait time' do
        expect(described_class.generate(user)).to include(state: 'supergood')
      end

      it 'returns a hash with decimal score (0–1) of user’s risk of falling to a lower grade' do
        expect(described_class.generate(user)).to include(percent: 0.0)
      end

      context 'and who belongs to a group with other tickets' do
        let(:ticket) { create(:ticket, group: group) }

        before do
          create(:ticket_article, sender_name: 'Customer', ticket: ticket, created_at: Time.current + 1.hour)
          create(:ticket_article, sender_name: 'Agent', ticket: ticket, created_at: Time.current + 2.hours)
        end

        it 'returns a hash with 1-day average ticket wait time across user’s groups (in minutes)' do
          expect(described_class.generate(user)).to include(average_per_agent: 60)
        end
      end
    end

    context 'when given an agent with recent (since start-of-day) customer exchanges' do
      let(:ticket) { create(:ticket, group: group, owner_id: user.id) }

      before do
        create(:ticket_article, sender_name: 'Customer', ticket: ticket, created_at: Time.current + 1.hour)
        create(:ticket_article, sender_name: 'Agent', ticket: ticket, created_at: Time.current + 2.hours)
      end

      it 'returns a hash with 1-day average ticket wait time for user (in minutes)' do
        expect(described_class.generate(user)).to include(handling_time: 60)
      end

      it 'returns a hash with 1-day average ticket wait time across user’s groups (in minutes)' do
        expect(described_class.generate(user)).to include(average_per_agent: 60)
      end

      it 'returns a hash with verbal grade for average ticket wait time' do
        expect(described_class.generate(user)).to include(state: 'supergood')
      end

      it 'returns a hash with decimal score (0–1) of user’s risk of falling to a lower grade' do
        expect(described_class.generate(user)).to include(percent: 1.0)
      end

      context 'and who belongs to a group with other tickets' do
        let(:other_ticket) { create(:ticket, group: group) }

        before do
          create(:ticket_article, sender_name: 'Customer', ticket: other_ticket, created_at: Time.current + 1.hour)
          create(:ticket_article, sender_name: 'Agent', ticket: other_ticket, created_at: Time.current + 3.hours)
        end

        it 'returns a hash with 1-day average ticket wait time across user’s groups (in minutes)' do
          expect(described_class.generate(user)).to include(average_per_agent: 90)
        end
      end
    end
  end

  describe '.calculate_average' do
    let(:ticket) { create(:ticket) }
    let(:start_time) { Time.current.beginning_of_day }

    context 'with empty tickets (no articles)' do
      it 'returns 0' do
        expect(described_class.calculate_average(ticket.id, start_time)).to eq(0)
      end
    end

    context 'with old articles (last message predates given start time)' do
      before do
        create(:ticket_article, sender_name: 'Customer', ticket: ticket, created_at: 1.day.ago)
        create(:ticket_article, sender_name: 'Agent', ticket: ticket, created_at: 1.day.ago)
      end

      it 'returns 0' do
        expect(described_class.calculate_average(ticket.id, start_time)).to eq(0)
      end
    end

    context 'with a single exchange' do
      before do
        create(:ticket_article, sender_name: 'Customer', ticket: ticket, created_at: start_time + 1.minute)
        create(:ticket_article, sender_name: 'Agent', ticket: ticket, created_at: start_time + 2.minutes)
      end

      it 'returns elapsed time' do
        expect(described_class.calculate_average(ticket.id, start_time)).to eq(1.minute)
      end
    end

    context 'with internal notes' do
      before do
        create(:ticket_article, sender_name: 'Customer', ticket: ticket, created_at: start_time + 1.minute)
        create(:ticket_article, sender_name: 'Agent', ticket: ticket, created_at: start_time + 2.minutes, internal: true)
        create(:ticket_article, sender_name: 'Agent', ticket: ticket, created_at: start_time + 3.minutes)
      end

      it 'ignores them (and measures time to actual response)' do
        expect(described_class.calculate_average(ticket.id, start_time)).to eq(2.minutes)
      end
    end

    context 'with multiple exchanges' do
      before do
        create(:ticket_article, sender_name: 'Customer', ticket: ticket, created_at: start_time + 1.minute)
        create(:ticket_article, sender_name: 'Agent', ticket: ticket, created_at: start_time + 2.minutes)
        create(:ticket_article, sender_name: 'Customer', ticket: ticket, created_at: start_time + 10.minutes)
        create(:ticket_article, sender_name: 'Agent', ticket: ticket, created_at: start_time + 15.minutes)
      end

      it 'returns average of elapsed times' do
        expect(described_class.calculate_average(ticket.id, start_time)).to eq(3.minutes)
      end
    end

    context 'with all above cases combined' do
      before do
        # empty ticket
        create(:ticket)

        # old messages
        create(:ticket_article, sender_name: 'Customer', ticket: ticket, created_at: 1.day.ago)
        create(:ticket_article, sender_name: 'Agent', ticket: ticket, created_at: 1.day.ago)

        # first exchange, with internal notes
        create(:ticket_article, sender_name: 'Customer', ticket: ticket, created_at: start_time + 1.minute)
        create(:ticket_article, sender_name: 'Agent', ticket: ticket, created_at: start_time + 90.seconds, internal: true)
        create(:ticket_article, sender_name: 'Agent', ticket: ticket, created_at: start_time + 2.minutes)

        # second exchange
        create(:ticket_article, sender_name: 'Customer', ticket: ticket, created_at: start_time + 10.minutes)
        create(:ticket_article, sender_name: 'Agent', ticket: ticket, created_at: start_time + 15.minutes)
      end

      it 'ignores all edge cases and returns only specified average response time' do
        expect(described_class.calculate_average(ticket.id, start_time)).to eq(3.minutes)
      end
    end
  end
end
