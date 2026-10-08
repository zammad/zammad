# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AddChannelMicrosoftGraph, type: :db_migration do
  before do
    setting = Setting.find_by(name: 'ticket_subject_size')
    setting.preferences[:permission] -= ['admin.channel_microsoft_graph']
    setting.save!
  end

  it 'does update settings with new permissions' do
    expect { migrate }
      .to change { Setting.find_by(name: 'ticket_subject_size').preferences[:permission] }
      .from(not_include('admin.channel_microsoft_graph'))
      .to(include('admin.channel_microsoft_graph'))
  end
end
