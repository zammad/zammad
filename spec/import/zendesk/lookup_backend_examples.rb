RSpec.shared_examples 'Lookup backend' do
  it 'responds to lookup' do
    expect(described_class).to respond_to('lookup')
  end
end
