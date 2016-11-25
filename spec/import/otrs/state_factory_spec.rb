require 'rails_helper'
require 'import/transaction_factory_examples'

RSpec.describe Import::OTRS::StateFactory do
  it_behaves_like 'Import::TransactionFactory'

  it 'creates a state backup in the pre_import_hook' do
    expect(described_class).to receive(:backup)
    described_class.pre_import_hook([])
  end
end
