# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/application_model_examples'
require 'models/concerns/can_be_imported_examples'
require 'models/concerns/has_object_manager_attributes_examples'
require 'models/concerns/has_collection_update_examples'
require 'models/concerns/has_xss_sanitized_note_examples'
require 'models/concerns/has_image_sanitized_note_examples'

RSpec.describe Group, type: :model do
  subject(:group) { create(:group) }

  it_behaves_like 'ApplicationModel'
  it_behaves_like 'CanBeImported'
  it_behaves_like 'HasObjectManagerAttributes'
  it_behaves_like 'HasCollectionUpdate', collection_factory: :group
  it_behaves_like 'HasXssSanitizedNote', model_factory: :group
  it_behaves_like 'HasImageSanitizedNote', model_factory: :group
  it_behaves_like 'Association clears cache', association: :users
  it_behaves_like 'Association clears cache', association: :roles

  describe 'name compatibility layer' do
    context 'when creating a new group' do
      context 'with name attribute' do
        let(:name) { Faker::Lorem.unique.word.capitalize }

        it 'sets name_last attribute to name' do
          expect(described_class.create(name: name)).to have_attributes(name_last: name)
        end

        context 'when using complete path' do
          let(:group1) { create(:group) }
          let(:group2) { create(:group, parent: group1) }
          let(:name)   { "#{group1.name_last}::#{group2.name_last}::#{Faker::Lorem.unique.word.capitalize}" }

          it 'sets parent_id attribute to guessed parent' do
            expect(described_class.create(name: name)).to have_attributes(parent_id: group2.id)
          end

          context 'when path is invalid' do
            let(:name) { Array.new(3) { Faker::Lorem.unique.word.capitalize }.join('::') }

            it 'raises validation error' do
              expect { described_class.create(name: name) }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Name contains invalid path')
            end
          end
        end
      end

      context 'with name_last attribute' do
        let(:name_last) { Faker::Lorem.unique.word.capitalize }

        it 'sets name_last attribute to name_last' do
          expect(described_class.create(name_last: name_last)).to have_attributes(name_last: name_last)
        end
      end

      context 'with both name and name_last attribute' do
        let(:name)      { Faker::Lorem.unique.word.capitalize }
        let(:name_last) { Faker::Lorem.unique.word.capitalize }

        it 'sets name_last attribute to name_last' do
          expect(described_class.create(name: name, name_last: name_last)).to have_attributes(name_last: name_last)
        end
      end
    end

    context 'when updating an existing group' do
      let(:group) { create(:group) }

      context 'with name attribute' do
        let(:name)  { Faker::Lorem.unique.word.capitalize }

        before do
          group.update!(name: name) if !defined?(skip_before)
        end

        it 'sets name_last attribute to name' do
          expect(group).to have_attributes(name_last: name)
        end

        context 'when using complete path' do
          let(:group1) { create(:group) }
          let(:group2) { create(:group, parent: group1) }
          let(:name)   { "#{group1.name_last}::#{group2.name_last}::#{Faker::Lorem.unique.word.capitalize}" }

          it 'sets parent_id attribute to guessed parent' do
            expect(group).to have_attributes(parent_id: group2.id)
          end

          context 'when path is invalid' do
            let(:name)        { Array.new(3) { Faker::Lorem.unique.word.capitalize }.join('::') }
            let(:skip_before) { true }

            it 'raises validation error' do
              expect { group.update!(name: name) }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Name contains invalid path')
            end
          end
        end
      end

      context 'with name_last attribute' do
        let(:name_last) { Faker::Lorem.unique.word.capitalize }

        before do
          group.update!(name_last: name_last)
        end

        it 'sets name_last attribute to name_last' do
          expect(described_class.create(name_last: name_last)).to have_attributes(name_last: name_last)
        end
      end

      context 'with both name and name_last attribute' do
        let(:name)      { Faker::Lorem.unique.word.capitalize }
        let(:name_last) { Faker::Lorem.unique.word.capitalize }

        before do
          group.update!(name: name, name_last: name_last)
        end

        it 'sets name_last attribute to name_last' do
          expect(described_class.create(name_last: name_last)).to have_attributes(name_last: name_last)
        end
      end
    end
  end

  describe 'tree related functions' do
    let!(:group_1)  { create(:group) }
    let!(:group_2)  { create(:group, parent: group_1) }
    let!(:group_31) { create(:group, parent: group_2) }
    let!(:group_32) { create(:group, parent: group_2) }
    let!(:group_4)  { create(:group, parent: group_31) }

    describe '#all_children' do
      it 'does return all children' do
        expect(group_1.all_children.sort).to eq([group_2, group_31, group_32, group_4].sort)
      end
    end

    describe '#all_parents' do
      it 'does return all parents ids' do
        expect(group_4.all_parents).to eq([group_31, group_2, group_1])
      end
    end

    describe '#depth' do
      it 'does return group depth' do
        expect(group_4.depth).to eq(3)
      end
    end

    describe '#check_max_depth' do
      let(:group_1_1)  { create(:group, name: 'tree_group_1_1') }
      let(:group_1_2)  { create(:group, name: 'tree_group_1_2', parent: group_1_1) }
      let(:group_1_3)  { create(:group, name: 'tree_group_1_3', parent: group_1_2) }
      let(:group_1_4)  { create(:group, name: 'tree_group_1_4', parent: group_1_3) }
      let(:group_1_5)  { create(:group, name: 'tree_group_1_5', parent: group_1_4) }
      let(:group_1_6)  { create(:group, name: 'tree_group_1_6', parent: group_1_5) }
      let(:group_1_7)  { create(:group, name: 'tree_group_1_7', parent: group_1_6) }
      let(:group_2_1)  { create(:group, name: 'tree_group_2_1') }
      let(:group_2_2)  { create(:group, name: 'tree_group_2_2', parent: group_2_1) }
      let(:group_2_3)  { create(:group, name: 'tree_group_2_3', parent: group_2_2) }
      let(:group_2_4)  { create(:group, name: 'tree_group_2_4', parent: group_2_3) }

      it 'does check depth on creation', :aggregate_failures do
        expect do
          group_1_1
          group_1_2
          group_1_3
          group_1_4
          group_1_5
          group_1_6
        end.not_to raise_error
        expect { group_1_7 }.to raise_error(Exceptions::UnprocessableEntity, 'This group or its children exceed the allowed nesting depth.')
      end

      it 'does check depth on tree merge', :aggregate_failures do
        expect do
          group_1_6
          group_2_4
        end.not_to raise_error
        expect { group_2_1.update(parent: group_1_6) }.to raise_error(Exceptions::UnprocessableEntity, 'This group or its children exceed the allowed nesting depth.')
      end
    end
  end
end
