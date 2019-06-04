RSpec.shared_context 'factory' do
  it 'saves successfully' do
    expect(subject).to be_persisted
  end
end
