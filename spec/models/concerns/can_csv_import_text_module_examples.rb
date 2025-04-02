# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'csv'

RSpec.shared_examples 'CanCsvImport - TextModule specific tests', :aggregate_failures do
  describe '.csv_example' do
    context 'when no data avaiable' do
      let(:headers) do
        CSV.parse(TextModule.csv_example).shift
      end

      it 'returns expected headers' do
        expect(headers).to start_with('id', 'name', 'keywords', 'content', 'note', 'active')
        expect(headers).not_to include('organization', 'state', 'owner', 'priority', 'customer')
      end
    end
  end

  describe '.csv_import' do
    let(:try)    { true }
    let(:delete) { false }
    let(:params) { { string: csv_string, parse_params: { col_sep: ';' }, try: try, delete: delete } }
    let(:result) { TextModule.csv_import(**params) }

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

      include_examples 'fails with error', ['Unable to parse empty file/string for TextModule.']
    end

    context 'with just CSV header line' do
      let(:csv_string) { 'name;keywords;content;note;active;' }

      include_examples 'fails with error', ['No records found in file/string for TextModule.']
    end

    context 'without required lookup header' do
      let(:csv_string) { "firstname;lastname;active;\nfirstname-simple-import1;lastname-simple-import1;;true\nfirstname-simple-import2;lastname-simple-import2;false\n" }

      include_examples 'fails with error', ['No lookup column like id,name for TextModule found.']
    end

    context 'with valid import data' do
      let(:csv_string) { "name;keywords;content;note;active;\nsome name1;keyword1;\"some\ncontent1\";-;\nsome name2;keyword2;some content<br>test123\n" }

      before do
        create(
          :text_module,
          name:     'some name1',
          content:  'some name1',
          keywords: 'keyword1',
          active:   true,
        )
        create(
          :text_module,
          name:     'name should be deleted',
          content:  'content should be deleted',
          keywords: 'keyword should be deleted',
          active:   true,
        )
      end

      context 'without :delete' do
        context 'with :try' do
          it 'returns success' do
            expect(result).to include({ try: try, result: 'success' })
            expect(result[:records].count).to be(2)
          end

          it 'does not import text modules' do
            expect { result }.not_to change(TextModule, :count)
          end
        end

        context 'without :try' do
          let(:try)        { false }
          let(:first_mod)  { TextModule.last(2).first }
          let(:second_mod) { TextModule.last }

          it 'returns success' do
            expect(result).to include({ try: try, result: 'success' })
            expect(result[:records].count).to be(2)
          end

          it 'does import organizations' do
            expect { result }.to change(TextModule, :count).by(1)
            expect(first_mod).to have_attributes(
              name:     'name should be deleted',
              keywords: 'keyword should be deleted',
              content:  'content should be deleted',
              active:   true,
            )
            expect(second_mod).to have_attributes(
              name:     'some name2',
              keywords: 'keyword2',
              content:  'some content<br>test123',
              active:   true,
            )
          end
        end
      end

      context 'with :delete' do
        let(:delete) { true }

        context 'with :try' do
          it 'returns success' do
            expect(result).to include({ try: try, result: 'success' })
            expect(result[:records].count).to be(2)
          end

          it 'does not import text modules' do
            expect { result }.not_to change(TextModule, :count)
          end
        end

        context 'without :try' do
          let(:try)        { false }
          let(:first_mod)  { TextModule.last(2).first }
          let(:second_mod) { TextModule.last }

          it 'returns success' do
            expect(result).to include({ try: try, result: 'success' })
            expect(result[:records].count).to be(2)
          end

          it 'does import organizations' do
            expect { result }.not_to change(TextModule, :count)
            expect(first_mod).to have_attributes(
              name:     'some name1',
              keywords: 'keyword1',
              content:  'some<br>content1',
              active:   true,
            )
            expect(second_mod).to have_attributes(
              name:     'some name2',
              keywords: 'keyword2',
              content:  'some content<br>test123',
              active:   true,
            )
          end
        end
      end
    end
  end
end
