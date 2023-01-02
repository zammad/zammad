# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'lib/import/transaction_factory_examples'

RSpec.describe Import::TransactionFactory do
  it_behaves_like 'Import::TransactionFactory'
  it_behaves_like 'Import::BaseFactory extender'
end
