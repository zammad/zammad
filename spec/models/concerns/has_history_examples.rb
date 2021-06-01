# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.shared_examples 'HasHistory' do |history_relation_object: []|
  describe 'auto-creation of history records' do
    let(:histories) { History.where(history_object_id: History::Object.find_by(name: described_class.name)) }

    context 'on creation' do
      it 'creates a History record for it' do
        expect { subject }.to change(histories, :count).by(1)
        expect(histories.last.history_type.name).to eq('created')
      end
    end

    context 'on update' do
      let(:histories) do
        History.where(history_object_id:    History::Object.lookup(name: described_class.name).id,
                      history_type_id:      History::Type.lookup(name: 'updated').id,
                      history_attribute_id: History::Attribute.find_or_create_by(name: attribute).id)
      end

      let!(:old_value) { subject.send(attribute) }

      shared_examples 'attribute update' do
        it 'creates a History record for it' do
          expect { subject.update(attribute => new_value) }.to change(histories, :count).by(1)
          expect(histories.last.attributes).to include(attributes)
        end
      end

      describe 'of #active', if: described_class.attribute_names.include?('active') do
        let(:attribute) { 'active' }
        let(:new_value) { !subject.active }
        let(:attributes) { { 'value_from' => old_value.to_s, 'value_to' => new_value.to_s } }

        include_examples 'attribute update'
      end

      describe 'of #body', if: described_class.attribute_names.include?('body') do
        let(:attribute) { 'body' }
        let(:new_value) { 'Lorem ipsum dolor' }
        let(:attributes) { { 'value_from' => old_value, 'value_to' => new_value } }

        include_examples 'attribute update'
      end

      describe 'of #email', if: described_class.attribute_names.include?('email') do
        let(:attribute) { 'email' }
        let(:new_value) { Faker::Internet.email }
        let(:attributes) { { 'value_from' => old_value, 'value_to' => new_value } }

        include_examples 'attribute update'
      end

      describe 'of #lastname', if: described_class.attribute_names.include?('lastname') do
        let(:attribute) { 'lastname' }
        let(:new_value) { 'Foo' }
        let(:attributes) { { 'value_from' => old_value, 'value_to' => new_value } }

        include_examples 'attribute update'
      end

      describe 'of #name', if: described_class.attribute_names.include?('name') do
        let(:attribute) { 'name' }
        let(:new_value) { 'Foo' }
        let(:attributes) { { 'value_from' => old_value, 'value_to' => new_value } }

        include_examples 'attribute update'
      end

      describe 'of #state', if: described_class.attribute_names.include?('state_id') do
        let(:attribute) { 'state' }
        let(:new_value) { state_class.where.not(id: old_value.id).first }
        let(:state_class) { "#{described_class.name}::State".constantize }
        let(:attributes) { { 'value_from' => old_value.name, 'value_to' => new_value.name } }

        include_examples 'attribute update'
      end

      describe 'of #title', if: described_class.attribute_names.include?('title') do
        let(:attribute) { 'title' }
        let(:new_value) { 'foo' }
        let(:attributes) { { 'value_from' => old_value, 'value_to' => new_value } }

        include_examples 'attribute update'
      end

      context 'when validations or callbacks prevent update' do
        shared_examples 'failed attribute update' do
          it 'does not create a History record for it' do
            expect { subject.update(attribute => new_value) }.not_to change(histories, :count)
          end
        end

        describe 'of #owner', if: described_class.attribute_names.include?('owner_id') do
          let(:attribute) { 'owner' }
          let(:new_value) { create(:customer) } # Ticket#owner is restricted to active agents of the same group

          include_examples 'failed attribute update'
        end
      end
    end
  end

  describe '#history_get' do
    context 'without "full" flag' do
      it 'delegates to History.list for self' do
        expect(History).to receive(:list).with(described_class.name, subject.id, history_relation_object)

        subject.history_get
      end
    end

    context 'with "full" flag' do
      it 'returns a hash including History.list for self' do
        expect(subject.history_get(true))
          .to include(history: History.list(described_class.name, subject.id, history_relation_object))
      end

      it 'returns a hash including FE assets of self and related objects' do
        expect(subject.history_get(true))
          .to include(assets: hash_including(subject.assets({})))
      end
    end
  end
end
