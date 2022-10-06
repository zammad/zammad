# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class EmailHelper
  class Verify

=begin

get result of inbound probe

  result = EmailHelper::Verify.email(
    inbound: {
      adapter: 'imap',
      options: {
        host: 'imap.gmail.com',
        port: 993,
        ssl: true,
        user: 'some@example.com',
        password: 'password',
      },
    },
    outbound: {
      adapter: 'smtp',
      options: {
        host: 'smtp.gmail.com',
        port: 25,
        ssl: true,
        user: 'some@example.com',
        password: 'password',
      },
    },
    sender: 'sender_and_recipient_of_verify_email@example.com',
  )

returns on success

  {
    result: 'ok'
  }

returns on fail

  {
    result: 'invalid',
    message: 'Verification Email not found in mailbox.',
    subject: subject,
  }

or

  {
    result: 'invalid',
    message: 'Authentication failed.',
    subject: subject,
  }

=end

    def self.email(params)

      # send verify email
      subject = params[:subject].presence || "##{SecureRandom.hex(10)}"
      result = EmailHelper::Probe.outbound(params[:outbound], params[:sender], subject)
      if result[:result] != 'ok'
        result[:source] = 'outbound'
        return result
      end

      # validate adapter
      adapter = params[:inbound][:adapter].downcase
      if !EmailHelper.available_driver[:inbound][adapter.to_sym]
        return {
          result:  'failed',
          message: "Unknown adapter '#{adapter}'",
        }
      end

      # looking for verify email
      9.times do
        sleep 5

        # fetch mailbox
        fetch_result = nil

        begin
          driver_class    = "Channel::Driver::#{adapter.to_classname}".constantize
          driver_instance = driver_class.new
          fetch_result    = driver_instance.fetch(params[:inbound][:options], self, 'verify', subject)
        rescue => e
          result = {
            result:        'invalid',
            source:        'inbound',
            message:       e.to_s,
            message_human: EmailHelper::Probe.translation(e.message),
            invalid_field: EmailHelper::Probe.invalid_field(e.message),
            subject:       subject,
          }
          return result
        end

        next if !fetch_result
        next if fetch_result[:result] != 'ok'

        return fetch_result
      end

      {
        result:  'invalid',
        message: __('Verification Email not found in mailbox.'),
        subject: subject,
      }
    end

  end

end
