RSpec.shared_examples 'HasObjectManagerAttributesValidation' do
  it 'validates ObjectManager::Attributes' do
    expect(described_class.validators.map(&:class)).to include(ObjectManager::Attribute::Validation)
  end
end
