# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.shared_examples 'HasObjectManagerAttributesValidation' do
  it 'validates ObjectManager::Attributes' do
    expect(described_class.validators.map(&:class)).to include(ObjectManager::Attribute::Validation)
  end
end
