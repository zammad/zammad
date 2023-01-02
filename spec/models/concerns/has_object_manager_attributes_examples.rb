# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'HasObjectManagerAttributes' do
  it 'validates ObjectManager::Attributes' do
    expect(described_class.validators.map(&:class)).to include(ObjectManager::Attribute::Validation)
  end

  context "when object attribute with name 'type' is used", db_strategy: :reset do
    before do
      skip('Skip context if a special type handling exists') if subject.try(:type_id)

      if !ObjectManager::Attribute.exists?(object_lookup: ObjectLookup.find_by(name: described_class.name), name: 'type')
        create(:object_manager_attribute_text, name: 'type', object_name: described_class.name)
        ObjectManager::Attribute.migration_execute
      end
    end

    it "check that the 'type' column can be updated" do
      expect { subject.reload.update(type: 'Example') }.not_to raise_error
    end

  end
end
