# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe UpdateApiPasswordAccessFrontend, type: :db_migration do
  before do
    Setting.find_by(name: 'api_password_access').update!(frontend: false)
  end

  it 'does update the setting' do
    expect { migrate }.to change { Setting.find_by(name: 'api_password_access').frontend }.from(false).to(true)
  end
end
