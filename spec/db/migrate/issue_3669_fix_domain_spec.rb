# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue3669FixDomain, type: :db_migration do
  let!(:channel) do
    channel_options = {
      inbound:  {
        adapter: 'imap',
        options: {
          auth_type: 'XOAUTH2',
          host:      'imap.gmail.com',
          ssl:       'ssl',
          user:      'example@gmail.com',
        },
      },
      outbound: {
        adapter: 'smtp',
        options: {
          host:           'smtp.gmail.com',
          domain:         'gmail.com',
          port:           465,
          ssl:            true,
          user:           'example@gmail.com',
          authentication: 'xoauth2',
        },
      },
      auth:     {
        provider:      'google',
        type:          'XOAUTH2',
        client_id:     'abc',
        client_secret: 'efg',
      },
    }

    Channel.create!(
      area:          'Google::Account',
      group_id:      Group.first.id,
      options:       channel_options,
      active:        false,
      created_by_id: 1,
      updated_by_id: 1,
    )
  end

  it 'removes domain from the configuration' do
    expect { migrate }.to change { channel.reload.options[:outbound][:options][:domain] }.to(nil)
  end
end
