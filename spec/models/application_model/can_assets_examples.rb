# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.shared_examples 'ApplicationModel::CanAssets' do |associations: [], selectors: [], own_attributes: true|
  subject { create(described_class.name.underscore, updated_by_id: admin.id) }

  let(:admin) { create(:admin) }

  describe '#assets (for supplying model data to front-end framework)' do
    shared_examples 'own asset attributes' do
      it 'returns a hash with own asset attributes' do
        expect(subject.assets({})[described_class.to_app_model])
          .to include(subject.id => hash_including(subject.attributes_with_association_ids))
      end
    end

    include_examples 'own asset attributes' if own_attributes

    describe 'for created_by & updated_by users' do
      let(:users) { User.where(id: subject.attributes.slice('created_by_id', 'updated_by_id').values) }
      let(:users_assets) { users.reduce({}) { |assets_hash, user| user.assets(assets_hash) } }

      it 'returns a hash with their asset attributes' do
        expect(subject.assets({})[:User]).to include(users_assets[:User])
      end
    end

    context 'when given a non-empty hash' do
      let(:hash) { { described_class.to_app_model => { foo: 'bar' } } }

      it 'deep-merges assets into it, in place' do
        expect { subject.assets(hash) }
          .to change { hash }
          .to(hash.deep_merge(subject.assets({})))
      end
    end

    Array(associations).each do |association|
      describe "for ##{association} association" do
        let(:reflection) { described_class.reflect_on_association(association) }

        shared_examples 'single association' do
          subject { create(described_class.name.underscore, association => single) }

          let(:single) { create(reflection.class_name.underscore) }

          it 'returns a hash with its asset attributes' do
            expect(subject.assets({})).to include(single.assets({}))
          end

          context 'after association has been modified' do
            it 'does not use a cached value' do
              subject.assets({})
              single.update(updated_by_id: User.last.id)

              expect(subject.assets({}).dig(reflection.klass.to_app_model, single.id))
                .to include(single.attributes_with_association_ids)
            end
          end
        end

        shared_examples 'collection association' do
          subject { create(described_class.name.underscore, association => collection) }

          let(:collection) { create_list(reflection.class_name.underscore, 5) }
          let(:collection_assets) { collection.reduce({}) { |assets_hash, single| single.assets(assets_hash) } }

          it 'returns a hash with their asset attributes' do
            expect(subject.assets({})).to include(collection_assets)
          end

          context 'after association has been modified' do
            it 'does not use a cached value' do
              subject.assets({})
              collection.first.update(updated_by_id: User.last.id)

              expect(subject.assets({}).dig(reflection.klass.to_app_model, collection.first.id))
                .to include(collection.first.attributes_with_association_ids)
            end
          end
        end

        if described_class.reflect_on_association(association).macro.in?(%i[has_one belongs_to])
          include_examples 'single association'
        else
          include_examples 'collection association'
        end
      end
    end

    Array(selectors).each do |s|
      subject { create(described_class.name.underscore, s => selector) }

      let(:selector) { { 'ticket.priority_id' => { operator: 'is', value: [1, 2] } } }
      let(:priorities_assets) { Ticket::Priority.first(2).reduce({}) { |asset_hash, priority| priority.assets(asset_hash) } }

      describe "for objects referenced in ##{s}" do
        it 'returns a hash with their asset attributes' do
          expect(subject.assets({})).to include(priorities_assets)
        end
      end
    end
  end
end
