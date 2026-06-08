# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Issue5170PGPMailResponse < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting
      .where(area: 'Postmaster::PreFilter')
      .find { |elem| elem.state_current[:value] == 'Channel::Filter::SecureMailing' }
      &.update!(name: '0001_postmaster_filter_secure_mailing')

    Setting
      .where(area: 'Postmaster::PreFilter')
      .find { |elem| elem.state_current[:value] == 'Channel::Filter::Trusted' }
      &.update!(name: '0000_postmaster_filter_trusted')
  end
end
