# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AddSettingOptionForPostmasterFollowUpSearchIn < ActiveRecord::Migration[7.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    setting = Setting.find_by(name: 'postmaster_follow_up_search_in')
    return if !setting

    # update options
    return if !setting.options[:form]
    return if !setting.options[:form][0]
    return if !setting.options[:form][0][:options]

    # setting is already updates
    return if setting.options[:form][0][:options]['subject_references']

    setting.options[:form][0][:options]['subject_references'] = 'Subject & References - Additional search for same article subject and same message ID in references header if no follow-up was recognized using default settings.'
    setting.save!

    # update setting
    update_setting
  end

  def update_setting

    # verify if setting value need to be updated
    current = Setting.get('postmaster_follow_up_search_in')
    return if !current || current.include?('subject_references')

    # prepare current setting value
    if current.instance_of?(String)
      current = [current]
    end

    # store new setting value
    current.push('subject_references')
    Setting.set('postmaster_follow_up_search_in', current)
  end

end
