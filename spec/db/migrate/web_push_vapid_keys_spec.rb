# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe WebPushVapidKeys, type: :db_migration do
  before do
    Setting.where(name: %w[web_push_vapid_private_key web_push_vapid_public_key]).destroy_all

    migrate
  end

  it 'creates a matching VAPID key pair' do
    public_key  = Setting.get('web_push_vapid_public_key')
    private_key = Setting.get('web_push_vapid_private_key')

    expect(WebPush::VapidKey.from_keys(public_key, private_key).public_key).to eq(public_key)
  end

  it 'delivers only the public key to the frontend', :aggregate_failures do
    expect(Setting.find_by(name: 'web_push_vapid_private_key')).to have_attributes(frontend: false)
    expect(Setting.find_by(name: 'web_push_vapid_public_key')).to have_attributes(frontend: true)
  end

  it 'treats the private key as sensitive' do
    expect(Setting.find_by(name: 'web_push_vapid_private_key')).to be_sensitive
  end
end
