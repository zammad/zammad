RSpec.shared_examples 'Import::Zendesk::LocalIDMapperHook' do

  it 'responds to local_id' do
    expect(described_class).to respond_to('local_id')
  end

  it 'responds to post_import_hook' do
    expect(described_class).to respond_to('post_import_hook')
  end

  it 'stores an ID mapping and makes it accessable' do
    backend_instance = double(
      zendesk_id: 31_337,
      id:         1337,
    )

    described_class.post_import_hook(nil, backend_instance)
    expect(described_class.local_id(backend_instance.zendesk_id)).to eq(backend_instance.id)
  end
end
