# Requires: let(:group_access_no_permission_instance) { ... }
RSpec.shared_examples 'HasGroups and Permissions' do

  context 'group' do

    let(:group_read) { create(:group) }

    before(:each) do
      group_access_no_permission_instance.group_names_access_map = {
        group_read.name => 'read',
      }
    end

    context '#group_access?' do

      it 'prevents instances without permissions' do
        expect(group_access_no_permission_instance.group_access?(group_read, 'read')).to be false
      end
    end

    context '#group_ids_access' do

      it 'prevents instances without permissions' do
        expect(group_access_no_permission_instance.group_ids_access('read')).to be_empty
      end
    end

    context '#groups_access' do

      it 'prevents instances without permissions' do
        expect(group_access_no_permission_instance.groups_access('read')).to be_empty
      end
    end

    context '#group_names_access_map' do

      it 'prevents instances without permissions' do
        expect(group_access_no_permission_instance.group_names_access_map).to be_empty
      end
    end

    context '#group_ids_access_map' do

      it 'prevents instances without permissions' do
        expect(group_access_no_permission_instance.group_ids_access_map).to be_empty
      end
    end

    context '#attributes_with_association_ids' do

      it 'prevents instances without permissions' do
        expect(group_access_no_permission_instance.attributes_with_association_ids['group_ids']).to be_empty
      end
    end

    context '#attributes_with_association_names' do

      it 'prevents instances without permissions' do
        expect(group_access_no_permission_instance.attributes_with_association_names['group_ids']).to be_empty
      end
    end

    context '.group_access' do

      it 'prevents instances without permissions' do
        result = described_class.group_access(group_read.id, 'read')
        expect(result).not_to include(group_access_no_permission_instance)
      end
    end

    context '.group_access_ids' do

      it 'prevents instances without permissions' do
        result = described_class.group_access(group_read.id, 'read')
        expect(result).not_to include(group_access_no_permission_instance.id)
      end
    end
  end
end
