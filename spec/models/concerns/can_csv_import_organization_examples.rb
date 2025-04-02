# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'csv'

RSpec.shared_examples 'CanCsvImport - Organization specific tests', :aggregate_failures do
  describe '.csv_example' do
    before do
      Organization.destroy_all
    end

    context 'when no data avaiable' do
      let(:headers) do
        CSV.parse(Organization.csv_example).shift
      end

      it 'returns expected headers' do
        expect(headers).to start_with('id', 'name', 'shared', 'domain', 'domain_assignment', 'active', 'vip', 'note')
        expect(headers).to include('members')
      end
    end
  end

  describe '.csv_import' do
    let(:try)    { true }
    let(:delete) { false }
    let(:params) { { string: csv_string, parse_params: { col_sep: ';' }, try: try, delete: delete } }
    let(:result) { Organization.csv_import(**params) }

    shared_examples 'fails with error' do |errors|
      shared_examples 'checks error handling' do
        it 'returns error(s)' do
          expect(result).to include({ try: try, result: 'failed', errors: errors })
        end

        it 'does not import organizations' do
          # Any single failure will cause the entire import to be aborted.
          expect { result }.not_to change(Organization, :count)
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

      include_examples 'fails with error', ['Unable to parse empty file/string for Organization.']
    end

    context 'with just CSV header line' do
      let(:csv_string) { 'id;name;shared;domain;domain_assignment;active;' }

      include_examples 'fails with error', ['No records found in file/string for Organization.']
    end

    context 'without required lookup header' do
      let(:csv_string) { "firstname;lastname;active;\nfirstname-simple-import1;lastname-simple-import1;;true\nfirstname-simple-import2;lastname-simple-import2;false\n" }

      include_examples 'fails with error', ['No lookup column like id,name for Organization found.']
    end

    context 'with invalid id' do
      let(:csv_string) { "id;name;shared;domain;domain_assignment;active;note;\n999999999;organization-simple-invalid_id-import1;\n;organization-simple-invalid_id-import2;\n" }

      include_examples 'fails with error', ["Line 1: unknown Organization with id '999999999'."]
    end

    context 'with invalid attributes' do
      let(:csv_string) { "name;note;not existing\norganization-invalid-import1;some note;abc\norganization-invalid-import2;some other note;123; with not exsiting header\n" }

      include_examples 'fails with error', [
        "Line 1: Unable to create record - unknown attribute 'not existing' for Organization.",
        "Line 2: Unable to create record - unknown attribute 'not existing' for Organization.",
      ]
    end

    context 'with delete' do
      let(:csv_string) { "id;name;shared;domain;domain_assignment;active;note\n;org-simple-import1;true;org-simple-import1.example.com;false;true;some note1\n;org-simple-import2;true;org-simple-import2.example.com;false;false;some note2\n" }
      let(:delete) { true }

      include_examples 'fails with error', ['Delete is not possible for Organization.']
    end

    context 'with valid import data' do
      let(:csv_string) { "id;name;shared;domain;domain_assignment;active;note\n;org-simple-import1;true;org-simple-import1.example.com;false;true;some note1\n;org-simple-import2;true;org-simple-import2.example.com;false;false;some note2\n" }

      context 'with :try' do
        it 'returns success' do
          expect(result).to include({ try: try, result: 'success' })
          expect(result[:records].count).to be(2)
        end

        it 'does not import organizations' do
          expect { result }.not_to change(Organization, :count)
        end
      end

      context 'without :try' do
        let(:try)        { false }
        let(:first_org)  { Organization.last(2).first }
        let(:second_org) { Organization.last }

        it 'returns success' do
          expect(result).to include({ try: try, result: 'success' })
          expect(result[:records].count).to be(2)
        end

        it 'does import organizations' do
          expect { result }.to change(Organization, :count).by(2)
          expect(first_org).to have_attributes(
            name:              'org-simple-import1',
            shared:            true,
            domain:            'org-simple-import1.example.com',
            domain_assignment: false,
            note:              'some note1',
            active:            true,
          )
          expect(second_org).to have_attributes(
            name:              'org-simple-import2',
            shared:            true,
            domain:            'org-simple-import2.example.com',
            domain_assignment: false,
            note:              'some note2',
            active:            false,
          )
        end
      end
    end

    context 'with valid import data including members' do
      let(:customer1) { create(:customer) }
      let(:customer2)  { create(:customer) }
      let(:csv_string) { "id;name;members;\n;organization-member-import1;\n;organization-member-import2;#{customer1.email}~~~#{customer2.email}" }

      context 'with :try' do
        it 'returns success' do
          expect(result).to include({ try: try, result: 'success' })
          expect(result[:records].count).to be(2)
        end

        it 'does not import organizations' do
          expect { result }.not_to change(Organization, :count)
        end
      end

      context 'without :try' do
        let(:try) { false }
        let(:first_org)  { Organization.last(2).first }
        let(:second_org) { Organization.last }

        it 'returns success' do
          expect(result).to include({ try: try, result: 'success' })
          expect(result[:records].count).to be(2)
        end

        it 'does import organizations' do
          expect { result }.to change(Organization, :count).by(2)
          expect(first_org).to have_attributes(
            name:    'organization-member-import1',
            members: have_attributes(count: 0)
          )
          expect(second_org).to have_attributes(
            name:    'organization-member-import2',
            members: have_attributes(count: 2)
          )
        end
      end
    end
  end
end
