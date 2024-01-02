# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe TechDebt297ThreeStateBoolean, db_strategy: :reset, type: :db_migration do
  it 'migrates users.vip' do
    change_column_null :users, :vip, true

    user = create(:user, vip: nil)

    expect { migrate }.to change { user.reload.vip }.from(nil).to(false)
  end
end
