# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe UpdateApiPasswordAccessFrontend, type: :db_migration do
  before do
    migrate
  end

  it 'does update the setting' do
    expect(Setting.find_by(name: 'api_password_access')[:frontend]).to be(true)
  end
end
