# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AuthThirdPartyNoCreateUser, db_strategy: :reset, type: :db_migration do
  before do
    Setting.find_by(name: 'auth_third_party_no_create_user')&.destroy
  end

  it 'creates setting' do
    migrate

    expect(Setting.find_by(name: 'auth_third_party_no_create_user')).to be_present
  end
end
