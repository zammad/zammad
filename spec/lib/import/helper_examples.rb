# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.shared_examples 'Import::Helper' do

  it 'responds to check_import_mode' do
    expect(described_class).to respond_to('check_import_mode')
  end

  it 'responds to log' do
    expect(described_class).to respond_to('log')
  end

  it 'responds to utf8_encode' do
    expect(described_class).to respond_to('utf8_encode')
  end

  it 'responds to reset_primary_key_sequence' do
    expect(described_class).to respond_to('reset_primary_key_sequence')
  end
end
