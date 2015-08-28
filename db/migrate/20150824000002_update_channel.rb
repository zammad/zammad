class UpdateChannel < ActiveRecord::Migration
  def up

    add_column :email_addresses, :channel_id, :integer, null: true
    EmailAddress.reset_column_information

    channel = Channel.find_by(area: 'Email::Inbound')
    EmailAddress.all.each {|email_address|
      email_address.channel_id = channel.id
      email_address.save
    }

    add_column :channels, :last_log_in, :text, limit: 500.kilobytes + 1, null: true
    add_column :channels, :last_log_out, :text, limit: 500.kilobytes + 1, null: true
    add_column :channels, :status_in, :string, limit: 100, null: true
    add_column :channels, :status_out, :string, limit: 100, null: true
    Channel.reset_column_information

    channel_outbound = Channel.find_by(area: 'Email::Outbound', active: true)

    Channel.all.each {|channel|
      if channel.area == 'Email::Inbound'
        channel.area = 'Email::Account'
        options = {
          inbound: {
            adapter: channel.adapter.downcase,
            options: channel.options,
          },
          outbound: {
            adapter: channel_outbound.adapter.downcase,
            options: channel_outbound.options,
          },
        }
        channel.options = options
        channel.save
      elsif channel.area == 'Email::Outbound'
        channel.area = 'Email::Notification'
        options = {
          outbound: {
            adapter: channel.adapter,
            options: channel.options,
          },
        }
        channel.options = options
        channel.save
      elsif channel.area == 'Twitter::Inbound'
        channel.area = 'Twitter::Account'
        channel.options[:adapter] = channel.adapter
        channel.save
      end
    }

    remove_column :channels, :adapter
    Channel.reset_column_information

  end
end
