require 'lib/import/factory_examples'

RSpec.shared_examples 'Import::Zendesk::BaseFactory' do
  it_behaves_like 'Import::Factory'

  it 'calls .all! on parameter object' do
    parameter = double()
    expect(parameter).to receive('all!')
    described_class.import(parameter)
  end

  it 'calls new on determined backend object' do
    expect(described_class).to receive(:backend_class).and_return(Class)
    expect(described_class).to receive('skip?')
    expect(described_class).to receive(:pre_import_hook)
    expect(described_class).to receive(:post_import_hook)
    record = double()
    expect(Class).to receive(:new).with(record, any_args)
    parameter = double()
    expect(parameter).to receive('all!').and_yield(record)
    described_class.import(parameter)
  end
end
