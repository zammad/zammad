# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'ApplicationModel::CanParam' do |sample_data_attribute: :name|
  describe '.param_cleanup' do
    let(:params) do
      attributes_for(described_class.name.underscore)
        .merge(abc: true, id: 123, created_at: Time.current, updated_at: Time.current)
    end

    context 'when a new object' do
      let(:clean_params) { described_class.param_cleanup(params, true) }

      context 'when import mode is off' do
        it 'does not include id' do
          expect(clean_params).not_to have_key(:id)
        end

        it 'includes data fields' do
          expect(clean_params).to include(sample_data_attribute => clean_params[sample_data_attribute])
        end

        it 'does not include a non-existing field' do
          expect(clean_params).not_to have_key(:abc)
        end

        it 'does not include created and updated fields' do
          expect(clean_params.keys)
            .not_to include(:created_by_id, :updated_by_id, :created_at, :updated_at)
        end

        it 'does not include action and controller' do
          expect(clean_params.keys)
            .not_to include(:action, :controler)
        end
      end

      context 'when import mode is on' do
        before { Setting.set('import_mode', true) }

        it 'does not include id' do
          expect(clean_params).not_to have_key(:id)
        end

        it 'includes data fields' do
          expect(clean_params).to include(sample_data_attribute => clean_params[sample_data_attribute])
        end

        it 'does not include a non-existing field' do
          expect(clean_params).not_to have_key(:abc)
        end

        it 'include created and updated fields' do
          expect(clean_params).to include(
            created_by_id: params[:created_by_id],
            updated_by_id: params[:updated_by_id],
            created_at:    params[:created_at],
            updated_at:    params[:updated_at],
          )
        end

        it 'does not include action and controller' do
          expect(clean_params.keys)
            .not_to include(:action, :controler)
        end
      end

    end

    context 'when an existing object' do
      let(:clean_params) { described_class.param_cleanup(params, false) }

      context 'when import mode is off' do
        it 'includes id' do
          expect(clean_params).to include(id: 123)
        end

        it 'includes data fields' do
          expect(clean_params).to include(sample_data_attribute => clean_params[sample_data_attribute])
        end

        it 'does not include a non-existing field' do
          expect(clean_params).not_to have_key(:abc)
        end

        it 'does not include created and updated fields' do
          expect(clean_params.keys)
            .not_to include(:created_by_id, :updated_by_id, :created_at, :updated_at)
        end

        it 'does not include action and controller' do
          expect(clean_params.keys)
            .not_to include(:action, :controler)
        end
      end

      context 'when import mode is on' do
        before { Setting.set('import_mode', true) }

        it 'includes id' do
          expect(clean_params).to include(id: 123)
        end

        it 'includes data fields' do
          expect(clean_params).to include(sample_data_attribute => clean_params[sample_data_attribute])
        end

        it 'does not include a non-existing field' do
          expect(clean_params).not_to have_key(:abc)
        end

        it 'include created and updated fields' do
          expect(clean_params).to include(
            created_by_id: params[:created_by_id],
            updated_by_id: params[:updated_by_id],
            created_at:    params[:created_at],
            updated_at:    params[:updated_at],
          )
        end

        it 'does not include action and controller' do
          expect(clean_params.keys)
            .not_to include(:action, :controler)
        end
      end
    end
  end

  if described_class.has_attribute?(:preferences)
    describe '.param_preferences_merge' do
      subject(:object) { create(described_class.name.underscore.downcase, preferences:) }

      let(:preferences) do
        { A: 1, B: 2 }
      end
      let(:clean_params)  { described_class.param_cleanup(params) }
      let(:merged_params) { object.param_preferences_merge(clean_params) }

      context 'when attribute contains other data' do
        let(:params) do
          { sample_data_attribute => '123' }
        end

        it 'keeps that data' do
          expect(merged_params).to include(sample_data_attribute => '123')
        end
      end

      context 'when preferences hash is given' do
        let(:params) do
          { preferences: { 'B' => 123, C: 256 } }
        end

        it 'merges hashes' do
          expect(merged_params[:preferences])
            .to include(
              'A' => 1,
              'B' => 123,
              'C' => 256
            )
        end
      end

      context 'when empty preferences hash is given' do
        let(:params) do
          { preferences: {} }
        end

        it 'keeps original hash' do
          expect(merged_params[:preferences])
            .to include(
              'A' => 1,
              'B' => 2,
            )
        end
      end
    end
  end

end
