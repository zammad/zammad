# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class MarkSettingsAsTranslatable < ActiveRecord::Migration[6.0]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    settings_update = %w[
      postmaster_follow_up_search_in
      postmaster_sender_based_on_reply_to
      ticket_define_email_from
      pretty_date_format
      storage_provider
      password_min_2_lower_2_upper_characters
      password_need_digit
      password_need_special_character
    ]

    settings_update.each do |name|
      fetched_setting = Setting.find_by(name: name)
      next if !fetched_setting

      fetched_setting.options = fetched_setting.options.tap do |options|
        options[:form].first[:translate] = true
      end

      fetched_setting.save!
    end
  end
end
