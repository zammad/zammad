# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Net::SMTP do
  let(:replies) { {} }
  let(:server)  { TCPServer.new('127.0.0.1', 0) }
  let(:port)    { server.addr[1] }

  let!(:server_thread) do
    Thread.new do
      loop do
        serve(server.accept)
      rescue IOError, SystemCallError
        break
      end
    end
  end

  after do
    server.close
    server_thread.join(5)
  end

  def serve(client)
    login_replies = []

    client.write("#{replies[:greeting] || '220 smtp.example.com ESMTP'}\r\n")

    while (line = client.gets)
      reply = login_replies.shift || reply_to(line)

      # An accepted AUTH LOGIN is followed by the user name and the password.
      login_replies = ['334 UGFzc3dvcmQ6', replies[:password] || '235 2.7.0 Authentication successful'] if line.start_with?('AUTH') && reply.start_with?('334')

      client.write("#{reply}\r\n")
    end
  ensure
    client.close
  end

  # The reply that is set for a command, and a positive one otherwise.
  def reply_to(command)
    case command
    when %r{\AEHLO}    then "250-smtp.example.com\r\n250 AUTH PLAIN LOGIN"
    when %r{\AAUTH}    then replies[:auth] || '334 VXNlcm5hbWU6'
    when %r{\ARCPT TO} then replies[:rcpt] || '250 2.1.5 Ok'
    when %r{\AQUIT}    then '221 2.0.0 Bye'
    else '250 2.0.0 Ok'
    end
  end

  def start(**, &)
    described_class.start('127.0.0.1', port, helo: 'zammad.example.com', starttls: false, **, &)
  end

  describe 'error of the session setup' do
    shared_examples 'raising an error with the mark of the session setup' do |klass, message|
      it "raises #{klass} with the mark and the reply of the server" do
        expect { start(**credentials) }
          .to raise_error(an_instance_of(klass).and(be_a(Net::SMTP::SessionSetupError)).and(have_attributes(message: message, response: be_present)))
      end
    end

    let(:credentials) { { user: 'zammad', secret: 'secret', authtype: :login } }

    context 'when the greeting is a negative reply' do
      let(:replies) { { greeting: '450 4.7.1 Service unavailable' } }

      it_behaves_like 'raising an error with the mark of the session setup', Net::SMTPServerBusy, %r{450 4\.7\.1 Service unavailable}
    end

    context 'when the first step of the login fails' do
      let(:replies) { { auth: '454 4.7.0 Temporary authentication failure' } }

      it_behaves_like 'raising an error with the mark of the session setup', Net::SMTPServerBusy, %r{454 4\.7\.0 Temporary authentication failure}
    end

    context 'when the last step of the login fails' do
      let(:replies) { { password: '535 5.7.8 Authentication credentials invalid' } }

      it_behaves_like 'raising an error with the mark of the session setup', Net::SMTPAuthenticationError, %r{535 5\.7\.8 Authentication credentials invalid}
    end

    context 'when the server refuses a recipient after the session setup' do
      let(:replies) { { rcpt: '454 4.7.1 <agent@example.org>: Relay access denied' } }

      it 'raises the error without the mark' do
        expect { start(**credentials) { |smtp| smtp.send_message("Subject: Test\r\n\r\nTest", 'zammad@example.com', 'agent@example.org') } }
          .to raise_error(an_instance_of(Net::SMTPServerBusy).and(satisfy('carry no mark of the session setup') { |error| !error.is_a?(Net::SMTP::SessionSetupError) }))
      end
    end
  end
end
