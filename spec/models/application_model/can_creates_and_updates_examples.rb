# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.shared_examples 'ApplicationModel::CanCreatesAndUpdates' do
  describe '.create_if_not_exists' do
    let!(:record) { create(described_class.name.underscore) }

    context 'when given a valid #id' do
      let(:id) { record.id }

      it 'returns that record' do
        expect(described_class.create_if_not_exists(id: id)).to eq(record)
      end

      it 'does not create a new record' do
        allow(described_class).to receive(:create)
        described_class.create_if_not_exists(id: id)
        expect(described_class).not_to have_received(:create).with(id: id)
      end
    end

    context 'when given an invalid #id' do
      let(:id) { described_class.pluck(:id).max + 1 }

      it 'attempts to create a new record' do
        allow(described_class).to receive(:create)
        described_class.create_if_not_exists(id: id)
        expect(described_class).to have_received(:create).with(id: id)
      end
    end

    shared_examples 'for #name attribute' do
      context 'when given a valid #name' do
        let(:name) { record.name }

        it 'returns that record' do
          expect(described_class.create_if_not_exists(name: name)).to eq(record)
        end

        it 'does not create a new record' do
          allow(described_class).to receive(:create)
          described_class.create_if_not_exists(name: name)
          expect(described_class).not_to have_received(:create).with(name: name)
        end
      end

      context 'when given an invalid #name' do
        let(:name) { "#{described_class.pluck(:name).max}foo" }

        it 'attempts to create a new record' do
          allow(described_class).to receive(:create)
          described_class.create_if_not_exists(name: name)
          expect(described_class).to have_received(:create).with(name: name)
        end
      end
    end

    shared_examples 'for #login attribute' do
      context 'when given a valid #login' do
        let(:login) { record.login }

        it 'returns that record' do
          expect(described_class.create_if_not_exists(login: login)).to eq(record)
        end

        it 'does not create a new record' do
          allow(described_class).to receive(:create)
          described_class.create_if_not_exists(login: login)
          expect(described_class).not_to have_received(:create).with(login: login)
        end
      end

      context 'when given an invalid #login' do
        let(:login) { "#{described_class.pluck(:login).max}foo" }

        it 'attempts to create a new record' do
          allow(described_class).to receive(:create)
          described_class.create_if_not_exists(login: login)
          expect(described_class).to have_received(:create).with(login: login)
        end
      end
    end

    shared_examples 'for #email attribute' do
      context 'when given a valid #email' do
        let(:email) { record.email }

        it 'returns that record' do
          expect(described_class.create_if_not_exists(email: email)).to eq(record)
        end

        it 'does not create a new record' do
          allow(described_class).to receive(:create)
          described_class.create_if_not_exists(email: email)
          expect(described_class).not_to have_received(:create).with(email: email)
        end
      end

      context 'when given an invalid #email' do
        let(:email) { "#{described_class.pluck(:email).max}foo" }

        it 'attempts to create a new record' do
          allow(described_class).to receive(:create)
          described_class.create_if_not_exists(email: email)
          expect(described_class).to have_received(:create).with(email: email)
        end
      end
    end

    shared_examples 'for #source and #locale attributes' do
      context 'when given a valid #source and #locale' do
        let(:source) { record.source }
        let(:locale) { record.locale }

        it 'returns that record' do
          expect(described_class.create_if_not_exists(source: source, locale: locale)).to eq(record)
        end

        it 'does not create a new record' do
          allow(described_class).to receive(:create)
          described_class.create_if_not_exists(source: source, locale: locale)
          expect(described_class).not_to have_received(:create).with(source: source, locale: locale)
        end
      end

      context 'when given an invalid #source or #locale' do
        let(:source) { "#{described_class.pluck(:source).max}foo" }
        let(:locale) { record.locale }

        it 'attempts to create a new record' do
          allow(described_class).to receive(:create)
          described_class.create_if_not_exists(source: source, locale: locale)
          expect(described_class).to have_received(:create).with(source: source, locale: locale)
        end
      end
    end

    include_examples 'for #name attribute' if described_class.attribute_names.include?('name')
    include_examples 'for #login attribute' if described_class.attribute_names.include?('login')
    include_examples 'for #email attribute' if described_class.attribute_names.include?('email')
    include_examples 'for #source and #locale attributes' if (described_class.attribute_names & %w[source locale]).many?
  end

  describe '.create_or_update' do
    let!(:record) { create(described_class.name.underscore) }
    let(:yesterday) { 1.day.ago }

    context 'when given a valid #id' do
      let(:id) { record.id }

      it 'updates other attributes on (and returns) that record' do
        expect { described_class.create_or_update(id: id, updated_at: yesterday) }
          .to change { record.reload.updated_at.to_i }.to(yesterday.to_i)
      end
    end

    context 'when given an invalid #id' do
      let(:id) { described_class.pluck(:id).max + 1 }

      it 'attempts to create a new record' do
        allow(described_class).to receive(:create)
        described_class.create_or_update(id: id)
        expect(described_class).to have_received(:create).with(id: id)
      end
    end

    shared_examples 'for #name attribute' do
      context 'when given a valid #name' do
        let(:name) { record.name }

        it 'updates other attributes on (and returns) that record' do
          expect { described_class.create_or_update(name: name, updated_at: yesterday) }
            .to change { record.reload.updated_at.to_i }.to(yesterday.to_i)
        end
      end

      context 'when given an invalid #name' do
        let(:name) { "#{described_class.pluck(:name).max}foo" }

        it 'attempts to create a new record' do
          allow(described_class).to receive(:create)
          described_class.create_or_update(name: name)
          expect(described_class).to have_received(:create).with(name: name)
        end
      end
    end

    shared_examples 'for #login attribute' do
      context 'when given a valid #login' do
        let(:login) { record.login }

        it 'updates other attributes on (and returns) that record' do
          expect { described_class.create_or_update(login: login, updated_at: yesterday) }
            .to change { record.reload.updated_at.to_i }.to(yesterday.to_i)
        end
      end

      context 'when given an invalid #login' do
        let(:login) { "#{described_class.pluck(:login).max}foo" }

        it 'attempts to create a new record' do
          allow(described_class).to receive(:create)
          described_class.create_or_update(login: login)
          expect(described_class).to have_received(:create).with(login: login)
        end
      end
    end

    shared_examples 'for #email attribute' do
      context 'when given a valid #email' do
        let(:email) { record.email }

        it 'updates other attributes on (and returns) that record' do
          expect { described_class.create_or_update(email: email, updated_at: yesterday) }
            .to change { record.reload.updated_at.to_i }.to(yesterday.to_i)
        end
      end

      context 'when given an invalid #email' do
        let(:email) { "#{described_class.pluck(:email).max}foo" }

        it 'attempts to create a new record' do
          allow(described_class).to receive(:create)
          described_class.create_or_update(email: email)
          expect(described_class).to have_received(:create).with(email: email)
        end
      end
    end

    shared_examples 'for #locale attribute' do
      context 'when given a valid #locale' do
        let(:locale) { record.locale }

        it 'updates other attributes on (and returns) that record' do
          expect { described_class.create_or_update(locale: locale, updated_at: yesterday) }
            .to change { record.reload.updated_at.to_i }.to(yesterday.to_i)
        end
      end

      context 'when given an invalid #locale' do
        let(:locale) { record.locale }

        it 'attempts to create a new record' do
          allow(described_class).to receive(:create)
          described_class.create_or_update(locale: locale)
          expect(described_class).to have_received(:create).with(locale: locale)
        end
      end
    end

    include_examples 'for #name attribute' if described_class.attribute_names.include?('name')
    include_examples 'for #login attribute' if described_class.attribute_names.include?('login')
    include_examples 'for #email attribute' if described_class.attribute_names.include?('email')
    include_examples 'for #locale attribute' if described_class.attribute_names.include?('locale')
  end
end
