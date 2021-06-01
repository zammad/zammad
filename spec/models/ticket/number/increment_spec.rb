# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Ticket::Number::Increment do
  describe '.generate' do
    let(:number) { described_class.generate }
    let(:system_id) { Setting.get('system_id') }
    let(:ticket_count) { Ticket::Counter.find_by(generator: 'Increment').content }

    it 'updates the "Increment" Ticket::Counter' do
      expect { number }
        .to change { Ticket::Counter.find_by(generator: 'Increment').content }
    end

    context 'with a "ticket_number_increment" setting with...' do
      context 'min_size: 5' do
        before { Setting.set('ticket_number_increment', { min_size: 5 }) }

        it 'returns a 5-character string' do
          expect(number).to be_a(String)
          expect(number.length).to be(5)
        end

        context 'when "system_id" setting exceeds :min_size' do
          before { Setting.set('system_id', 123_456) }

          it 'still adheres to numbering pattern (and does not require padding zeroes)' do
            expect(number).to match(%r{^#{system_id}#{ticket_count}$})
          end
        end

        it 'returns a string following the pattern system_id + padding zeroes + ticket_count' do
          expect(number).to match(%r{^#{system_id}0*#{ticket_count}$})
        end

        context '/ checksum: false (default)' do
          before { Setting.set('ticket_number_increment', { min_size: 5, checksum: false }) }

          it 'returns a 5-character string' do
            expect(number).to be_a(String)
            expect(number.length).to be(5)
          end

          it 'returns a string following the pattern system_id + padding zeroes + ticket_counter' do
            expect(number).to match(%r{^#{system_id}0*#{ticket_count}$})
          end

          context 'when "system_id" setting exceeds :min_size' do
            before { Setting.set('system_id', 123_456) }

            it 'still adheres to numbering pattern (and does not require padding zeroes)' do
              expect(number).to match(%r{^#{system_id}#{ticket_count}$})
            end
          end
        end

        context '/ checksum: true' do
          before { Setting.set('ticket_number_increment', { min_size: 5, checksum: true }) }

          it 'returns a 5-character string' do
            expect(number).to be_a(String)
            expect(number).to eq(number.to_i.to_s)
            expect(number.length).to be(5)
          end

          it 'returns a string following the pattern system_id + padding zeroes + ticket_counter + checksum' do
            expect(number).to match(%r{^#{system_id}0*#{ticket_count}\d$})
          end

          context 'when "system_id" setting exceeds :min_size' do
            before { Setting.set('system_id', 123_456) }

            it 'still adheres to numbering pattern (and does not require padding zeroes)' do
              expect(number).to match(%r{^#{system_id}#{ticket_count}\d$})
            end
          end
        end
      end
    end
  end

  describe '.check' do
    context 'for tickets with increment-style numbers' do
      let(:ticket) { create(:ticket, number: ticket_number) }
      let(:ticket_number) { "#{Setting.get('system_id')}0001" }
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
