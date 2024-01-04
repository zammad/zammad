# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'csv'

RSpec.shared_examples 'CanCsvImport - Ticket specific tests', :aggregate_failures do
  describe '.csv_example' do
    before do
      Ticket.destroy_all
    end

    context 'when no data avaiable' do
      let(:headers) do
        CSV.parse(Ticket.csv_example).shift
      end

      it 'returns expected headers' do
        expect(headers).to start_with('id', 'number', 'title', 'note', 'first_response_at', 'first_response_escalation_at')
        expect(headers).to include('organization', 'priority', 'state', 'owner', 'customer')
      end
    end
  end

  describe '.csv_import' do
    let(:try)    { true }
    let(:params) { { string: csv_string, parse_params: { col_sep: ';' }, try: try } }
    let(:result) { Ticket.csv_import(**params) }

    shared_examples 'fails with error' do |errors|
      shared_examples 'checks error handling' do
        it 'returns error(s)' do
          expect(result).to include({ try: try, result: 'failed', errors: errors })
        end

        it 'does not import tickets' do
          # Any single failure will cause the entire import to be aborted.
          expect { result }.not_to change(Ticket, :count)
        end
      end

      context 'with :try' do
        include_examples 'checks error handling'
      end

      context 'without :try' do
        let(:try) { false }

        include_examples 'checks error handling'
      end
    end

    context 'with empty string' do
      let(:csv_string) { '' }

      include_examples 'fails with error', ['Unable to parse empty file/string for Ticket.']
    end

    context 'with just CSV header line' do
      let(:csv_string) { 'id;number;title;state;priority;' }

      include_examples 'fails with error', ['No records found in file/string for Ticket.']
    end

    context 'without required lookup header' do
      let(:csv_string) { "firstname;lastname;active;\nfirstname-simple-import1;lastname-simple-import1;;true\nfirstname-simple-import2;lastname-simple-import2;false\n" }

      include_examples 'fails with error', ['No lookup column like id,number for Ticket found.']
    end

    context 'with invalid id' do
      let(:csv_string) { "id;number;title;state;priority;owner;customer;group;note\n999999999;123456;some title1;new;2 normal;-;nicole.braun@zammad.org;Users;some note1\n;123457;some title2;closed;1 low;-;nicole.braun@zammad.org;Users;some note2\n" }

      include_examples 'fails with error', ["Line 1: unknown Ticket with id '999999999'."]
    end

    context 'with invalid attributes' do
      let(:csv_string) { "id;number;not_existing;state;priority;owner;customer;group;note\n;123456;some title1;new;2 normal;-;nicole.braun@zammad.org;Users;some note1\n;123457;some title2;closed;1 low;-;nicole.braun@zammad.org;Users;some note2\n" }

      include_examples 'fails with error', [
        "Line 1: Unable to create record - unknown attribute 'not_existing' for Ticket.",
        "Line 2: Unable to create record - unknown attribute 'not_existing' for Ticket.",
      ]
    end

    context 'with valid import data' do
      let(:csv_string) { "id;number;title;state;priority;owner;customer;group;note\n;123456;some title1;new;2 normal;-;nicole.braun@zammad.org;Users;some note1\n;123457;some title2;closed;1 low;-;nicole.braun@zammad.org;Users;some note2\n" }

      context 'with :try' do
        it 'returns success' do
          expect(result).to include({ try: try, result: 'success' })
          expect(result[:records].count).to be(2)
        end

        it 'does not import tickets' do
          expect { result }.not_to change(Ticket, :count)
        end
      end

      context 'without :try' do
        let(:try)           { false }
        let(:first_ticket)  { Ticket.last(2).first }
        let(:second_ticket) { Ticket.last }

        it 'returns success' do
          expect(result).to include({ try: try, result: 'success' })
          expect(result[:records].count).to be(2)
        end

        it 'does import tickets' do
          expect { result }.to change(Ticket, :count).by(2)
          expect(first_ticket).to have_attributes(
            number:   '123456',
            title:    'some title1',
            note:     'some note1',
            state:    have_attributes(name: 'new'),
            priority: have_attributes(name: '2 normal'),
            owner:    have_attributes(login: '-'),
            customer: have_attributes(login: 'nicole.braun@zammad.org'),
          )
          expect(second_ticket).to have_attributes(
            number:   '123457',
            title:    'some title2',
            note:     'some note2',
            state:    have_attributes(name: 'closed'),
            priority: have_attributes(name: '1 low'),
            owner:    have_attributes(login: '-'),
            customer: have_attributes(login: 'nicole.braun@zammad.org'),
          )
        end
      end
    end
  end
end
