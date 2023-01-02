# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'Import factory' do
  it 'responds to import' do
    expect(described_class).to respond_to('import')
  end
end
