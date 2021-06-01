# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.shared_examples 'Import::Async' do
  it 'responds to start_bg' do
    expect(described_class).to respond_to('start_bg')
  end

  it 'responds to status_bg' do
    expect(described_class).to respond_to('status_bg')
  end
end
