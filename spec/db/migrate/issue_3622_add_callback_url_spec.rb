# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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
    Setting.where("name LIKE 'auth_%_credentials'").each do |setting|
      setting.options['form'].reject! { |form_field| form_field['name'] == 'callback_url' }
      setting.save!
    end
  end

  it 'does update settings correctly' do
    expect { migrate }
      .to change { Setting.find_by(name: 'auth_twitter_credentials').options['form'] }
      .from(not_include(field))
      .to(include(field))
  end
end
