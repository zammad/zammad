# Requires: let!(:group_relation_instance) { ... }
RSpec.shared_examples 'HasGroupRelationDefinition' do

  let(:group_relation_model_key) { group_relation_instance.model_name.element }

  context 'relation creation' do

    it 'refreshes updated_at of related instances' do
      group = create(:group)

      travel 1.minute

      expect do
        described_class.create!(
          group_relation_model_key => group_relation_instance,
          group: group
        )
      end.to change {
        group.reload.updated_at
      }.and change {
        group_relation_instance.reload.updated_at
      }
    end
  end

  context 'related instance deletion' do

    it 'refreshes updated_at of group instance' do
      group = create(:group)

      described_class.create!(
        group_relation_model_key => group_relation_instance,
        group: group
      )

      travel 1.minute

      expect do
        group.destroy
      end.to change {
        group_relation_instance.reload.updated_at
      }
    end

    it 'refreshes updated_at of relation instance' do
      group = create(:group)

      described_class.create!(
        group_relation_model_key => group_relation_instance,
        group: group
      )

      travel 1.minute

      expect do
        group_relation_instance.destroy
      end.to change {
        group.reload.updated_at
      }
    end
  end
end
