# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue4410AccountLinkingNotification, type: :db_migration do
  before do
    Setting.find_by(name: 'auth_third_party_linking_notification').destroy!

    migrate
  end

  it 'does create auth_third_party_linking_notification setting' do
    expect(Setting.exists?(name: 'auth_third_party_linking_notification')).to be(true)
  end
end
