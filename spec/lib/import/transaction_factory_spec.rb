# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'lib/import/base_factory_examples'

RSpec.describe Import::TransactionFactory do
  it_behaves_like 'Import::BaseFactory extender'

  it 'imports the records in a transaction', :aggregate_failures do
    in_transaction = false
    allow(ActiveRecord::Base).to receive(:transaction) do |&block|
      in_transaction = true
      block.call
    ensure
      in_transaction = false
    end
    allow(described_class).to receive(:import_action) { expect(in_transaction).to be(true) }

    described_class.import([double])

    expect(described_class).to have_received(:import_action)
  end
end
