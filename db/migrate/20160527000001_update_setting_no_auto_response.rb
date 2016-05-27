class UpdateSettingNoAutoResponse < ActiveRecord::Migration
  def up
    # can be deleted later, db/seeds.rb already updated
    Setting.create_or_update(
      title: 'Block Notifications',
      name: 'send_no_auto_response_reg_exp',
      area: 'Email::Base',
      description: 'If this regex matches, no notification will be send by the sender.',
      options: {
        form: [
          {
            display: '',
            null: false,
            name: 'send_no_auto_response_reg_exp',
            tag: 'input',
          },
        ],
      },
      state: '(mailer-daemon|postmaster|abuse|root|noreply|noreply.+?|no-reply|no-reply.+?)@.+?\..+?',
      preferences: { online_service_disable: true },
      frontend: false
    )
  end
end
