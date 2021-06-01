# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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
    allow(described_class).to receive(:backend_class).and_return(Class)
    allow(Class).to receive(:new)

    described_class.import([record])
    expect(Class).to have_received(:new).with(record, any_args)
  end
end
