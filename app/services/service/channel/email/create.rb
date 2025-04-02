# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::Channel::Email::Create < Service::Base

  def execute(inbound_configuration:, outbound_configuration:, group:, email_address:, email_realname:, group_email_address: false)

    new_channel = ::Channel.create!(
      area:         'Email::Account',
      options:      {
        inbound:  inbound_configuration,
        outbound: outbound_configuration,
      },
      group:        group,
      last_log_in:  nil,
      last_log_out: nil,
      status_in:    'ok',
      status_out:   'ok',
      active:       true,
    ).tap do |channel|
      set_email_address(channel:, email_address:, email_realname:)
    end

    if group_email_address
      Service::Channel::Email::UpdateDestinationGroupEmail.new(group:, channel: new_channel).execute
    end

    new_channel
  end

  private

  def set_email_address(channel:, email_address:, email_realname:)
    address = if ::Channel.one?
                # on initial setup, use placeholder email address
                EmailAddress.first
              else
                # remember address && set channel for email address
                EmailAddress.find_by(email: email_address)
              end

    address ||= EmailAddress.new

    address.name    = email_realname
    address.email   = email_address
    address.active  = true
    address.channel = channel

    address.save!
  end

end
