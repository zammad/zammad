RSpec.shared_examples 'Import::OTRS::Diff' do
  it 'responds to diff_worker' do
    expect(described_class).to respond_to('diff_worker')
  end
end
