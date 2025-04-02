# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AddChannelMicrosoftGraph, type: :db_migration do
  it 'does update settings with new permissions' do
    expect { migrate }.to change { Setting.find_by(name: 'ticket_subject_size').preferences[:permission] }.to include('admin.channel_microsoft_graph')
  end
end
