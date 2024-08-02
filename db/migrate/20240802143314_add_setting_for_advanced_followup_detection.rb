# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class AddSettingForAdvancedFollowupDetection < ActiveRecord::Migration[7.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Advanced follow-ups detection based on subject and refereces header',
      name:        'postmaster_follow_up_detection_subject_references',
      area:        'Email::Base',
      description: 'This is an advanced follow-up detection. If no follow-up was recognized by the regular settings, but in Zammad an article with the same subject and a message id, which is present in the References header of the incoming email - this email is recognized as a follow-up.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'postmaster_follow_up_detection_subject_references',
            tag:     'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state:       true,
      preferences: {
        permission: ['admin.channel_email', 'admin.channel_google', 'admin.channel_microsoft365'],
      },
      frontend:    false
    )

  end
end
