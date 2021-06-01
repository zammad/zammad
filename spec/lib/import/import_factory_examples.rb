# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.shared_examples 'Import factory' do
  it 'responds to import' do
    expect(described_class).to respond_to('import')
  end
end
