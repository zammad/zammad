# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class SettingDeliveryPermanentFailed < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    setting = Setting.find_by(name: '0900_postmaster_filter_bounce_check')
    if setting
      setting.name = '0900_postmaster_filter_bounce_follow_up_check'
      setting.state = 'Channel::Filter::BounceFollowUpCheck'
      setting.save!
    else
      Setting.create_if_not_exists(
        title:       'Defines postmaster filter.',
        name:        '0900_postmaster_filter_bounce_follow_up_check',
        area:        'Postmaster::PreFilter',
        description: 'Defines postmaster filter to identify postmaster bounced - to handle it as follow-up of the original ticket.',
        options:     {},
        state:       'Channel::Filter::BounceFollowUpCheck',
        frontend:    false
      )
    end
    Setting.create_if_not_exists(
      title:       'Defines postmaster filter.',
      name:        '0950_postmaster_filter_bounce_delivery_permanent_failed',
      area:        'Postmaster::PreFilter',
      description: 'Defines postmaster filter to identify postmaster bounced - disable sending notification on permanent deleivery failed.',
      options:     {},
      state:       'Channel::Filter::BounceDeliveryPermanentFailed',
      frontend:    false
    )

  end

end
