# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.shared_examples 'CanCsvImport' do |unique_attributes: []|
  describe '.csv_import' do
    let!(:params) { { string: <<~CSV, parse_params: { col_sep: ',' } } }
      #{described_class.attribute_names.join(',')}
      #{build(factory).attributes.values.join(',')}
    CSV

    let(:factory) { described_class.name.underscore }

    context 'with duplicate entries for unique attributes' do
      shared_examples 'case-insensitive duplicates' do |attribute|
        let!(:params) { { string: <<~CSV, parse_params: { col_sep: ',' } } }
          #{described_class.attribute_names.join(',')}
          #{build(factory, attribute => 'Foo').attributes.values.join(',')}
          #{build(factory, attribute => 'FOO').attributes.values.join(',')}
        CSV

        it 'cancels import' do
          expect { described_class.csv_import(**params) }
            .not_to change(described_class, :count)
        end

        it 'reports the duplicate' do
          expect(described_class.csv_import(**params))
            .to include(result: 'failed')
        end
      end

      Array(unique_attributes).each do |attribute|
        include_examples 'case-insensitive duplicates', attribute
      end
    end

    context 'when record creation unexpectedly fails' do
      around do |example|
        described_class.validate { errors.add(:base, 'Unexpected failure!') }
        example.run
        described_class._validate_callbacks.send(:chain).pop
        described_class.send(:set_callbacks, :validate, described_class._validate_callbacks.dup)
      end

      context 'during a dry-run' do
        before { params.merge!(try: 'true') }

        it 'reports the failure' do
          expect(described_class.csv_import(**params))
            .to include(result: 'failed')
        end
      end
    end
  end
end
