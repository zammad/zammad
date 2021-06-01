# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class AgentCustomer < ActiveRecord::Migration[5.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Role.where(name: %w[Admin Agent Customer]).each do |role|
      role.preferences.delete(:not)
      role.update_column(:preferences, role.preferences) # rubocop:disable Rails/SkipsModelValidations
    end

    move_filter
  end

  def move_filter
    Setting.find_by(name: '0010_postmaster_filter_trusted').update(name: '0005_postmaster_filter_trusted')
    Setting.find_by(name: '0020_postmaster_filter_auto_response_check').update(name: '0006_postmaster_filter_auto_response_check')
    Setting.find_by(name: '0100_postmaster_filter_follow_up_check').update(name: '0007_postmaster_filter_follow_up_check')
    Setting.find_by(name: '0110_postmaster_filter_follow_up_merged').update(name: '0008_postmaster_filter_follow_up_merged')
  end
end
