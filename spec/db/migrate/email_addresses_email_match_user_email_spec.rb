# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe EmailAddressesEmailMatchUserEmail, type: :db_migration do
  before do
    change_column :email_addresses, :email, :string, limit: 250
    EmailAddress.reset_column_information
  end

  it 'changes length' do
    expect { migrate }
      .to change { EmailAddress.column_for_attribute(:email).sql_type_metadata.limit }.to(255)
  end
end
