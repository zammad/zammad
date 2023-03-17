# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue3622AddCallbackUrl, type: :db_migration do
  let(:field) do
    {
      'display'  => 'Your callback URL',
      'null'     => true,
      'name'     => 'callback_url',
      'tag'      => 'auth_provider',
      'provider' => 'auth_twitter'
    }
  end

  before do
    migrate
  end

  it 'does update settings correctly' do
    expect(Setting.find_by(name: 'auth_twitter_credentials').options['form']).to include(field)
  end
end
