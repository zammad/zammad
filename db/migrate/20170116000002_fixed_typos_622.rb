# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class FixedTypos622 < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    setting = Setting.find_by(name: 'ticket_define_email_from_seperator')
    return if !setting

    setting.name = 'ticket_define_email_from_separator'
    setting.options[:form][0][:name] = 'ticket_define_email_from_separator'
    setting.save!

    setting_map = {
      'password_min_size'                       => 'Password needs to have at least minimal size of characters.',
      'password_min_2_lower_2_upper_characters' => 'Password needs to contain 2 lower and 2 upper characters.',
      'password_need_digit'                     => 'Password needs to have at least one digit.',
      'ticket_subject_size'                     => 'Max size of the subject in an email reply.',
      'postmaster_follow_up_search_in'          => 'In default the follow-up check is done via the subject of an email. With this setting you can add more fields where the follow-up check is executed.',
    }

    setting_map.each do |key, description|
      local_setting = Setting.find_by(name: key)
      next if !local_setting

      local_setting.description = description
      local_setting.save!
    end

    Translation.sync

  end
end
