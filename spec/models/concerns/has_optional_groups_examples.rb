# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'HasOptionalGroups' do |model_factory:|
  it_behaves_like 'Association clears cache', association: :groups

  describe '.available_in_groups' do
    let(:group)  { create(:group) }
    let(:object) { create(model_factory, groups:) }

    before { object }

    context 'when object has a group' do
      let(:groups) { [group] }

      it 'returns object if group matches' do
        expect(described_class.available_in_groups([group]))
          .to include(object)
      end

      it 'returns object if one of groups matches' do
        expect(described_class.available_in_groups([group, create(:group)]))
          .to include(object)
      end

      it 'does not return object if group does not match' do
        expect(described_class.available_in_groups([create(:group)]))
          .not_to include(object)
      end

      context 'when object is inactive' do
        before { object.update!(active: false) }

        it 'does not return inactive macros' do
          expect(described_class.available_in_groups([group]))
            .not_to include(object)
        end
      end
    end

    context 'when object has multiple groups' do
      let(:groups) { [group, create(:group)] }

      it 'returns object if one of given group matches' do
        expect(described_class.available_in_groups([group]))
          .to include(object)
      end

      it 'returns object if one of given groups matches' do
        expect(described_class.available_in_groups([group, create(:group)]))
          .to include(object)
      end

      it 'does not return object if no group matches' do
        expect(described_class.available_in_groups([create(:group)]))
          .not_to include(object)
      end

      context 'when object is inactive' do
        before { object.update!(active: false) }

        it 'does not return inactive macros' do
          expect(described_class.available_in_groups([group]))
            .not_to include(object)
        end
      end
    end

    context 'when object has no group limitations' do
      let(:groups) { [] }

      it 'returns object for any group' do
        expect(described_class.available_in_groups([group]))
          .to include(object)
      end

      context 'when object is inactive' do
        before { object.update!(active: false) }

        it 'does not return inactive macros' do
          expect(described_class.available_in_groups([group]))
            .not_to include(object)
        end
      end
    end
  end
end
