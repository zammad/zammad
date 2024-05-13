# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::AccessToken::Create do
  let(:user)       { create(:user) }
  let(:name)       { Faker::Lorem.word }
  let(:permission) { %w[ticket.agent] }
  let(:expires_at) { 1.day.from_now.to_date }

  it 'creates persistent API token with given permissions' do
    token = described_class.new(user, name:, permission:).execute

    expect(token).to have_attributes(
      user:        user,
      name:        name,
      action:      'api',
      persistent:  true,
      expires_at:  nil,
      preferences: include(permission: permission)
    )
  end

  it 'creates token with given expiration time' do
    token = described_class.new(user, name:, permission:, expires_at:).execute

    expect(token).to have_attributes(
      user:        user,
      name:        name,
      action:      'api',
      persistent:  true,
      expires_at:  expires_at,
      preferences: include(permission: permission)
    )
  end
end
