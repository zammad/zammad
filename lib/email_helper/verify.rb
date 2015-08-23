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
    sender: 'sender@example.com',
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
      if !params[:subject]
        subject = '#' + rand(99_999_999_999).to_s
      else
        subject = params[:subject]
      end
      result = EmailHelper::Probe.outbound( params[:outbound], params[:sender], subject )

      # looking for verify email
      (1..5).each {
        sleep 10

        # fetch mailbox
        found = nil

        begin
          if params[:inbound][:adapter] =~ /^imap$/i
            found = Channel::Imap.new.fetch( { options: params[:inbound][:options] }, 'verify', subject )
          else
            found = Channel::Pop3.new.fetch( { options: params[:inbound][:options] }, 'verify', subject )
          end
        rescue => e
          rresult {
            result: 'invalid',
            message: e.to_s,
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
