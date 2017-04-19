RSpec.shared_examples 'Auth backend' do

  it 'responds to #valid?' do
    expect(instance).to respond_to(:valid?)
  end
end
