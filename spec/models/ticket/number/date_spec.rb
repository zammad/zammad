# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Ticket::Number::Date do
  describe '.generate' do
    let(:number) { described_class.generate }

    before { travel_to(Time.zone.parse('1955-11-05')) }

    it 'updates the "Date" Ticket::Counter' do
      expect { number }
        .to change { Ticket::Counter.find_by(generator: 'Date')&.content }
    end

    context 'with a "ticket_number_date" setting with checksum: false (default)' do
      context 'and a single-digit system_id' do
        before { Setting.set('system_id', 1) }

        it 'returns a string following the pattern date + system_id + zero-padded number' do
          expect(number).to eq('1955110510001')
        end
      end

      context 'and a two-digit system_id' do
        before { Setting.set('system_id', 88) }

        it 'returns a string following the pattern date + system_id + zero-padded number' do
          expect(number).to eq('19551105880001')
        end
      end
    end

    context 'with a "ticket_number_date" setting with checksum: true' do
      before { Setting.set('ticket_number_date', { checksum: true }) }

      context 'and a single-digit system_id' do
        before { Setting.set('system_id', 1) }

        it 'returns a string following the pattern date + system_id + zero-padded number + checksum' do
          expect(number).to eq('19551105100012')
        end
      end

      context 'and a two-digit system_id' do
        before { Setting.set('system_id', 88) }

        it 'returns a string following the pattern date + system_id + zero-padded number + checksum' do
          expect(number).to eq('195511058800012')
        end
      end
    end
  end

  describe '.check' do
    context 'for tickets with date-style numbers' do
      let(:ticket) { create(:ticket, number: ticket_number) }
      let(:ticket_number) { "19551105#{Setting.get('system_id')}0001" }
      let(:check_query) { ticket.subject_build(ticket.title) }

      context 'when system_id is the same as when ticket was created' do
        before do
          Setting.set('system_id', 1)
          ticket  # create ticket
        end

        it 'returns the ticket matching the number in the given string' do
          expect(described_class.check(check_query)).to eq(ticket)
        end
      end

      context 'when system_id is different from when ticket was created' do
        before do
          Setting.set('system_id', 1)
          ticket  # create ticket
          Setting.set('system_id', 999)
        end

        it 'returns nil' do
          expect(described_class.check(check_query)).to be(nil)
        end

        context 'and "ticket_number_ignore_system_id" is true' do
          before { Setting.set('ticket_number_ignore_system_id', true) }

          it 'returns the ticket matching the number in the given string' do
            expect(described_class.check(check_query)).to eq(ticket)
          end
        end
      end
    end
  end
end
