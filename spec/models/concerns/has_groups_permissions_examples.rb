# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.shared_examples 'HasGroups and Permissions' do |group_access_no_permission_factory:|
  context 'group' do
    subject { build(group_access_no_permission_factory) }

    let(:group_read) { create(:group) }

    before do
      subject.group_names_access_map = {
        group_read.name => 'read',
      }
    end

    describe '#group_access?' do

      it 'prevents instances without permissions' do
        expect(subject.group_access?(group_read, 'read')).to be false
      end
    end

    describe '#group_ids_access' do

      it 'prevents instances without permissions' do
        expect(subject.group_ids_access('read')).to be_empty
      end
    end

    describe '#groups_access' do

      it 'prevents instances without permissions' do
        expect(subject.groups_access('read')).to be_empty
      end
    end

    describe '#group_names_access_map' do

      it 'prevents instances without permissions' do
        expect(subject.group_names_access_map).to be_empty
      end
    end

    describe '#group_ids_access_map' do

      it 'prevents instances without permissions' do
        expect(subject.group_ids_access_map).to be_empty
      end
    end

    describe '#attributes_with_association_ids' do

      it 'prevents instances without permissions' do
        expect(subject.attributes_with_association_ids['group_ids']).to be_empty
      end
    end

    describe '#attributes_with_association_names' do

      it 'prevents instances without permissions' do
        expect(subject.attributes_with_association_names['group_ids']).to be_empty
      end
    end

    describe '.group_access' do

      it 'prevents instances without permissions' do
        result = described_class.group_access(group_read.id, 'read')
        expect(result).not_to include(subject)
      end
    end

    describe '.group_access_ids' do

      it 'prevents instances without permissions' do
        result = described_class.group_access(group_read.id, 'read')
        expect(result).not_to include(subject.id)
      end
    end
  end
end
