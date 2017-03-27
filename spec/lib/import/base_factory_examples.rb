require 'lib/import/import_factory_examples'

RSpec.shared_examples 'Import::BaseFactory' do
  it_behaves_like 'Import factory'

  it 'responds to pre_import_hook' do
    expect(described_class).to respond_to('pre_import_hook')
  end
  it 'responds to post_import_hook' do
    expect(described_class).to respond_to('post_import_hook')
  end
  it 'responds to backend_class' do
    expect(described_class).to respond_to('backend_class')
  end
  it 'responds to skip?' do
    expect(described_class).to respond_to('skip?')
  end
end

RSpec.shared_examples 'Import::BaseFactory extender' do
  it 'calls new on determined backend object' do
    record = double()
    expect(described_class).to receive(:backend_class).and_return(Class)
    expect(Class).to receive(:new).with(record, any_args)
    described_class.import([record])
  end
end
