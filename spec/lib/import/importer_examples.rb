# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'Import backend' do
  it 'responds to start' do
    expect(described_class).to respond_to('start')
  end
end
