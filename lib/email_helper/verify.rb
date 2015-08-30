module EmailHelper
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
    message: 'Authentication failed!.',
    subject: subject,
  }

=end

    def self.email(params)

      # send verify email
      if !params[:subject] || params[:subject].empty?
        subject = '#' + rand(99_999_999_999).to_s
      else
        subject = params[:subject]
      end
      result = EmailHelper::Probe.outbound(params[:outbound], params[:sender], subject)
      if result[:result] != 'ok'
        result[:source] = 'outbound'
        return result
      end

      # validate adapter
      adapter = params[:inbound][:adapter].downcase
      if !EmailHelper.available_driver[:inbound].include?(adapter)
        return {
          result: 'failed',
          message: "Unknown adapter '#{adapter}'",
        }
        return
      end

      # looking for verify email
      (1..10).each {
        sleep 5

        # fetch mailbox
        found = nil

        begin
          require "channel/driver/#{adapter.to_filename}"

          driver_class    = Object.const_get("Channel::Driver::#{adapter.to_classname}")
          driver_instance = driver_class.new
          found           = driver_instance.fetch(params[:inbound][:options], self, 'verify', subject)
        rescue => e
          result = {
            result: 'invalid',
            source: 'inbound',
            message: e.to_s,
            message_human: EmailHelper::Probe.translation(e.message),
            invalid_field: EmailHelper::Probe.invalid_field(e.message),
            subject: subject,
          }
          return result
        end

        next if !found
        next if found != 'verify ok'

        return {
          result: 'ok',
        }

      }

      {
        result: 'invalid',
        message: 'Verification Email not found in mailbox.',
        subject: subject,
      }
    end

  end

end
