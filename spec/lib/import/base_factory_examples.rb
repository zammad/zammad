# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'Import::BaseFactory extender' do
  it 'calls new on determined backend object' do
    record = double
    allow(described_class).to receive(:backend_class).and_return(Class)
    allow(Class).to receive(:new)

    described_class.import([record])
    expect(Class).to have_received(:new).with(record, any_args)
  end
end
