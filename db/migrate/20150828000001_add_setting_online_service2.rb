class AddSettingOnlineService2 < ActiveRecord::Migration
  def up

    # add preferences
    add_column :channels, :preferences, :string, limit: 2000, null: true
    Channel.reset_column_information
    Channel.where(area: 'Email::Notification').each {|channel|
      channel.preferences = {}
      channel.preferences[:online_service_disable] = true
      channel.save
    }
    Channel.where(area: 'Email::Account').each {|channel|
      next if !channel.options
      next if !channel.options[:options]
      next if !channel.options[:options][:host]
      next if channel.options[:options][:host] !~ /zammad/i
      channel.preferences[:online_service_disable] = true
      channel.save
    }

    add_column :email_addresses, :preferences, :string, limit: 2000, null: true
    EmailAddress.reset_column_information
    EmailAddress.all.each {|email_address|
      next if email_address.email !~ /zammad/i
      email_address.preferences = {}
      email_address.preferences[:online_service_disable] = true
      email_address.save
    }

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

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
      state: '(MAILER-DAEMON|postmaster|abuse)@.+?\..+?',
      preferences: { online_service_disable: true },
      frontend: false
    )

  end

end
