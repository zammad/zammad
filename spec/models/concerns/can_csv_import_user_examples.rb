# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'csv'

RSpec.shared_examples 'CanCsvImport - User specific tests', :aggregate_failures do
  describe '.csv_example' do
    context 'when no data avaiable' do
      let(:headers) do
        CSV.parse(User.csv_example).shift
      end

      it 'returns expected headers' do
        expect(headers).to start_with('id', 'login', 'firstname', 'lastname', 'email')
        expect(headers).to include('organization')
      end
    end
  end

  describe '.csv_import' do
    let(:try)    { true }
    let(:delete) { false }
    let(:params) { { string: csv_string, parse_params: { col_sep: ';' }, try: try, delete: delete } }
    let(:result) { User.csv_import(**params) }

    shared_examples 'fails with error' do |errors|
      shared_examples 'checks error handling' do
        it 'returns error(s)' do
          expect(result).to include({ try: try, result: 'failed', errors: errors })
        end

        it 'does not import users' do
          # Any single failure will cause the entire import to be aborted.
          expect { result }.not_to change(User, :count)
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

      include_examples 'fails with error', ['Unable to parse empty file/string for User.']
    end

    context 'with just CSV header line' do
      let(:csv_string) { "login;firstname;lastname;email;active;\n" }

      include_examples 'fails with error', ['No records found in file/string for User.']
    end

    context 'without required lookup header' do
      let(:csv_string) { "firstname;lastname;active;\nfirstname-simple-import1;lastname-simple-import1;;true\nfirstname-simple-import2;lastname-simple-import2;false\n" }

      include_examples 'fails with error', ['No lookup column like id,login,email for User found.']
    end

    context 'with invalid id' do
      let(:csv_string) { "id;login;firstname;lastname;email;active;\n999999999;user-simple-invalid_id-import1;firstname-simple-import1;lastname-simple-import1;user-simple-invalid_id-import1@example.com;true\n;user-simple-invalid_id-import2;firstname-simple-import2;lastname-simple-import2;user-simple-invalid_id-import2@example.com;false\n" }

      include_examples 'fails with error', ["Line 1: unknown User with id '999999999'."]
    end

    context 'with readonly id' do
      let(:csv_string) { "id;login;firstname;lastname;email;active;\n1;user-simple-readonly_id-import1;firstname-simple-import1;lastname-simple-import1;user-simple-readonly_id-import1@example.com;true\n;user-simple-readonly_id-import2;firstname-simple-import2;lastname-simple-import2;user-simple-readonly_id-import2@example.com;false\n" }

      include_examples 'fails with error', ["Line 1: unable to update User with id '1'."]
    end

    context 'with invalid attributes' do
      let(:csv_string) { "login;firstname2;lastname;email\nuser-invalid-import1;firstname-invalid-import1;firstname-invalid-import1;user-invalid-import1@example.com\nuser-invalid-import2;firstname-invalid-import2;firstname-invalid-import2;user-invalid-import2@example.com\n" }

      include_examples 'fails with error', [
        "Line 1: Unable to create record - unknown attribute 'firstname2' for User.",
        "Line 2: Unable to create record - unknown attribute 'firstname2' for User.",
      ]
    end

    context 'with delete' do
      let(:csv_string) { "login;firstname;lastname;email\nuser-simple-import-fixed1;firstname-simple-import-fixed1;lastname-simple-import-fixed1;user-simple-import-fixed1@example.com\nuser-simple-import-fixed2;firstname-simple-import-fixed2;lastname-simple-import-fixed2;user-simple-import-fixed2@example.com\n" }
      let(:delete)     { true }

      include_examples 'fails with error', ['Delete is not possible for User.']
    end

    context 'with duplicates' do
      let(:csv_string) { "login;firstname;lastname;email\nuser-duplicate-import1;firstname-duplicate-import1;firstname-duplicate-import1;user-duplicate-import1@example.com\nuser-duplicate-import2;firstname-duplicate-import2;firstname-duplicate-import2;user-duplicate-import2@example.com\nuser-duplicate-import2;firstname-duplicate-import3;firstname-duplicate-import3;user-duplicate-import3@example.com" }

      include_examples 'fails with error', ['Line 3: duplicate record found.']
    end

    context 'with references to nonexisting organizations' do
      let(:csv_string) { "login;firstname;lastname;email;organization\nuser-reference-import1;firstname-reference-import1;firstname-reference-import1;user-reference-import1@example.com;organization-reference-import1\nuser-reference-import2;firstname-reference-import2;firstname-reference-import2;user-reference-import2@example.com;organization-reference-import2\nuser-reference-import3;firstname-reference-import3;firstname-reference-import3;user-reference-import3@example.com;Zammad Foundation\n" }

      include_examples 'fails with error', [
        "Line 1: No lookup value found for 'organization': \"organization-reference-import1\"",
        "Line 2: No lookup value found for 'organization': \"organization-reference-import2\"",
      ]

      context 'when organizations are available' do
        before do
          create(:organization, name: 'organization-reference-import1')
          create(:organization, name: 'organization-reference-import2')
        end

        let(:try) { false }
        let(:first_user)   { User.last(3).first }
        let(:second_user)  { User.last(3).second }
        let(:third_user)   { User.last }

        it 'returns success' do
          expect(result).to include({ try: try, result: 'success' })
          expect(result[:records].count).to be(3)
        end

        it 'does import users' do
          expect { result }.to change(User, :count).by(3)
          expect(first_user.organization.name).to eq('organization-reference-import1')
          expect(second_user.organization.name).to eq('organization-reference-import2')
          expect(third_user.organization.name).to eq('Zammad Foundation')
        end
      end
    end

    context 'with valid import data' do
      let(:csv_string)               { "login;firstname;lastname;email;active;\nuser-simple-IMPORT1;firstname-simple-import1;lastname-simple-import1;user-simple-IMPORT1@example.com ;true\nuser-simple-import2;firstname-simple-import2;lastname-simple-import2;user-simple-import2@example.com;false\n" }
      let(:csv_string_without_email) { "login;firstname;lastname;email;active;\nuser-simple-IMPORT1;firstname-simple-import1;lastname-simple-import1;user-simple-IMPORT1@example.com ;true\nuser-simple-import2;firstname-simple-import2;lastname-simple-import2;;false\n" }
      let(:second_result)            { User.csv_import(**params) }
      let(:second_params)            { { string: second_csv_string, parse_params: { col_sep: ';' }, try: try, delete: delete } }

      context 'with :try' do
        it 'returns success' do
          expect(result).to include({ try: try, result: 'success' })
          expect(result[:records].count).to be(2)
        end

        it 'does not import users' do
          expect { result }.not_to change(User, :count)
        end
      end

      context 'without :try' do
        let(:try) { false }
        let(:first_user)  { User.last(2).first }
        let(:second_user) { User.last }

        it 'returns success' do
          expect(result).to include({ try: try, result: 'success', records: have_attributes(count: 2), stats: { created: 2, updated: 0 } })
          expect(second_result).to include({ try: try, result: 'success', records: have_attributes(count: 2), stats: { created: 0, updated: 2 } })
        end

        it 'does import users' do
          expect { result }.to change(User, :count).by(2)
          expect(first_user).to have_attributes(
            login:     'user-simple-import1',
            firstname: 'firstname-simple-import1',
            lastname:  'lastname-simple-import1',
            email:     'user-simple-import1@example.com',
            active:    true,
          )
          expect(second_user).to have_attributes(
            login:     'user-simple-import2',
            firstname: 'firstname-simple-import2',
            lastname:  'lastname-simple-import2',
            email:     'user-simple-import2@example.com',
            active:    false,
          )

          expect { second_result }.not_to change(User, :count)

          expect(first_user.reload).to have_attributes(
            login:     'user-simple-import1',
            firstname: 'firstname-simple-import1',
            lastname:  'lastname-simple-import1',
            email:     'user-simple-import1@example.com',
            active:    true,
          )
          # Email is still present, though missing in CSV.
          expect(second_user.reload).to have_attributes(
            login:     'user-simple-import2',
            firstname: 'firstname-simple-import2',
            lastname:  'lastname-simple-import2',
            email:     'user-simple-import2@example.com',
            active:    false,
          )
        end
      end
    end

    context 'with roles and fixed params' do
      let(:result) { User.csv_import(**params, fixed_params: { note: 'some note' }) }
      let(:csv_string) do
        "login;firstname;lastname;email;roles;\nuser-role-import1;firstname-role-import1;lastname-role-import1;user-role-import1@example.com;Customer;\nuser-role-import2;firstname-role-import2;lastname-role-import2;user-role-import2@example.com;Agent~~~Admin"
      end

      context 'with :try' do
        it 'returns success' do
          expect(result).to include({ try: try, result: 'success' })
          expect(result[:records].count).to be(2)
        end

        it 'does not import users' do
          expect { result }.not_to change(User, :count)
        end
      end

      context 'without :try' do
        let(:try)         { false }
        let(:first_user)  { User.last(2).first }
        let(:second_user) { User.last }

        it 'returns success' do
          expect(result).to include({ try: try, result: 'success', records: have_attributes(count: 2), stats: { created: 2, updated: 0 } })
        end

        it 'does import users with roles' do
          expect { result }.to change(User, :count).by(2)
          expect(first_user.roles.count).to be(1)
          expect(first_user.note).to eq('some note')
          expect(second_user.roles.count).to be(2)
          expect(second_user.note).to eq('some note')
        end
      end
    end
  end
end
