# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe EmailHelper::Probe do
  describe '.outbound' do
    subject(:probe_result) { described_class.outbound(outbound_params, sender, *arguments, **options) }

    let(:outbound_params) do
      {
        adapter: adapter,
        options: {
          host:     'smtp.example.com',
          port:     587,
          user:     'sender@example.com',
          password: 'password',
        },
      }
    end

    let(:adapter)   { 'smtp' }
    let(:sender)    { 'sender@example.com' }
    let(:arguments) { [] }
    let(:options)   { {} }
    let(:error)     { nil }
    let(:mail)      { instance_double(Mail::Message, delivery_method: nil) }

    def smtp_error(klass, reply)
      klass.new(Net::SMTP::Response.parse(reply))
    end

    # Net::SMTP marks an error of the greeting, of EHLO, STARTTLS and of the login this way.
    def session_setup_error(klass, reply)
      smtp_error(klass, reply).extend(Net::SMTP::SessionSetupError)
    end

    # Net::SMTP raises a reply to the DATA command that is not a 3xx with this class, whatever its code.
    def smtp_data_error(reply)
      response = Net::SMTP::Response.parse(reply)

      Net::SMTPUnknownError.new(response, message: "could not get 3xx (#{response.status}: #{response.string})")
    end

    # Net::SMTP sends QUIT while the error of the session is raised, which makes that error the cause.
    def quit_error(error, session_error)
      raise error, cause: session_error
    rescue => e
      e
    end

    before do
      allow(Channel::EmailBuild).to receive(:build).and_return(mail)

      if error
        allow(mail).to receive(:deliver).and_raise(error)
      else
        allow(mail).to receive(:deliver)
      end
    end

    shared_examples 'reporting a refusal' do
      it 'marks the invalid result as refused' do
        expect(probe_result).to include(result: 'invalid', refused: true, message: include(error.message))
      end
    end

    shared_examples 'reporting a plain failure' do
      it 'returns an invalid result without the refusal marker' do
        expect(probe_result).to include(result: 'invalid').and not_include(:refused)
      end
    end

    context 'when the server accepts the test mail' do
      it { is_expected.to eq(result: 'ok') }

      it 'sends the test mail to the external address' do
        probe_result

        expect(Channel::EmailBuild).to have_received(:build).with(
          include(
            from: sender,
            to:   'verify-external-smtp-sending@discard.zammad.org',
            body: include('to an external address'),
          ),
          anything,
        )
      end
    end

    context 'when the server refuses the test mail' do
      context 'with a permanent error' do
        let(:error) { smtp_error(Net::SMTPFatalError, '554 5.7.1 Relay access denied') }

        it_behaves_like 'reporting a refusal'
      end

      context 'with a syntax error' do
        let(:error) { smtp_error(Net::SMTPSyntaxError, '501 5.1.3 Bad recipient address syntax') }

        it_behaves_like 'reporting a refusal'
      end

      context 'with a reply to the DATA command' do
        let(:error) { smtp_data_error('550 5.7.244 External sending is not supported for HVE accounts.') }

        it_behaves_like 'reporting a refusal'
      end

      context 'with a reply that was accepted as success before' do
        [
          '554 5.7.1 <verify-external-smtp-sending@discard.zammad.org>: Recipient address rejected: Access denied',
          '450 4.1.2 <verify-external-smtp-sending@discard.zammad.org>: Recipient address rejected: Domain not found',
          '450 4.1.1 <verify-external-smtp-sending@discard.zammad.org>: Recipient address rejected: unverified address: Address verification in progress',
          '450 4.1.8 <sender@example.com>: Sender address rejected: Domain not found',
        ].each do |reply|
          context "with '#{reply}'" do
            let(:error) { smtp_error(reply.start_with?('4') ? Net::SMTPServerBusy : Net::SMTPFatalError, reply) }

            it_behaves_like 'reporting a refusal'
          end
        end
      end
    end

    context 'when the server refuses the test mail with a temporary error' do
      [
        '454 4.7.1 <verify-external-smtp-sending@discard.zammad.org>: Relay access denied',
        '451 4.1.8 Domain of sender address sender@example.com does not resolve',
        '450 4.7.1 Empfaenger abgelehnt, nur interne Zustellung',
        '451 4.7.500 Server busy. Please try again later from [192.0.2.1]',
        '452 4.3.1 Insufficient system storage',
      ].each do |reply|
        context "with '#{reply}'" do
          let(:error) { smtp_error(Net::SMTPServerBusy, reply) }

          it_behaves_like 'reporting a refusal'
        end
      end

      context 'with a reply to the DATA command' do
        let(:error) { smtp_data_error('451 4.3.0 Mail server temporarily rejected message') }

        it_behaves_like 'reporting a refusal'
      end
    end

    context 'when the reply is about the connection' do
      [
        '421 4.3.2 Service not available, closing transmission channel',
        '421 4.7.0 smtp.example.com Error: too many connections from 192.0.2.1',
      ].each do |reply|
        context "with '#{reply}'" do
          let(:error) { smtp_error(Net::SMTPServerBusy, reply) }

          it_behaves_like 'reporting a plain failure'
        end
      end
    end

    context 'when QUIT fails after the server has refused the test mail' do
      shared_examples 'reporting the refusal in place of the failed QUIT' do
        it 'marks the invalid result as refused and names the reply to the test mail' do
          expect(probe_result).to include(result: 'invalid', refused: true, message: 'smtp.example.com: 550 5.7.1 Unable to relay')
        end
      end

      let(:refusal) { smtp_error(Net::SMTPFatalError, '550 5.7.1 Unable to relay') }

      context 'with a closed connection' do
        let(:error) { quit_error(EOFError.new('end of file reached'), refusal) }

        it_behaves_like 'reporting the refusal in place of the failed QUIT'
      end

      context 'with a reply about the connection' do
        let(:error) { quit_error(smtp_error(Net::SMTPServerBusy, '421 4.7.0 Error: too many errors'), refusal) }

        it_behaves_like 'reporting the refusal in place of the failed QUIT'
      end
    end

    context 'when QUIT fails after a reply about the connection' do
      let(:error) { quit_error(EOFError.new('end of file reached'), smtp_error(Net::SMTPServerBusy, '421 4.3.2 Service not available, closing transmission channel')) }

      it 'returns an invalid result without the refusal marker, which names that reply' do
        expect(probe_result)
          .to include(result: 'invalid', message: 'smtp.example.com: 421 4.3.2 Service not available, closing transmission channel')
          .and not_include(:refused)
      end
    end

    context 'when QUIT fails after an accepted test mail' do
      let(:error) { EOFError.new('end of file reached') }

      it_behaves_like 'reporting a plain failure'
    end

    context 'when the reply to the DATA command is not a negative one' do
      let(:error) { smtp_data_error('250 2.0.0 Ok') }

      it_behaves_like 'reporting a plain failure'
    end

    context 'when the reply has a code at the limit of a range' do
      {
        399 => 'reporting a plain failure',
        400 => 'reporting a refusal',
        419 => 'reporting a refusal',
        420 => 'reporting a plain failure',
        439 => 'reporting a plain failure',
        440 => 'reporting a refusal',
        529 => 'reporting a refusal',
        530 => 'reporting a plain failure',
        539 => 'reporting a plain failure',
        540 => 'reporting a refusal',
        599 => 'reporting a refusal',
        600 => 'reporting a plain failure',
      }.each do |code, behaviour|
        context "with #{code}" do
          let(:error) { smtp_data_error("#{code} Reply of the server") }

          it_behaves_like behaviour
        end
      end
    end

    context 'when the session setup fails with a code of the refusals' do
      {
        'with a greeting that turns the client away'   => [Net::SMTPFatalError, '554 5.7.1 Service unavailable; Client host [192.0.2.1] blocked'],
        'with a greeting that asks to come back later' => [Net::SMTPServerBusy, '450 4.7.1 Service unavailable'],
        'with STARTTLS that is not available'          => [Net::SMTPServerBusy, '454 4.7.0 TLS not available due to local problem'],
        'with a login that fails for the moment'       => [Net::SMTPAuthenticationError, '454 4.7.0 Temporary authentication failure'],
        'with a login that fails at its first step'    => [Net::SMTPServerBusy, '454 4.7.0 Temporary authentication failure'],
      }.each do |name, (klass, reply)|
        context name do
          let(:error) { session_setup_error(klass, reply) }

          it_behaves_like 'reporting a plain failure'
        end
      end
    end

    context 'when the test mail could not be handed over' do
      context 'with a failed login' do
        let(:error) { session_setup_error(Net::SMTPAuthenticationError, '535 5.7.8 Authentication credentials invalid') }

        it_behaves_like 'reporting a plain failure'
      end

      context 'with a missing login that the server names in reply to the sender' do
        let(:error) { smtp_error(Net::SMTPAuthenticationError, '530 5.7.57 Client not authenticated to send mail') }

        it_behaves_like 'reporting a plain failure'
      end

      context 'with a missing login that the server names in reply to the DATA command' do
        let(:error) { smtp_data_error('530 5.7.57 Client not authenticated to send mail') }

        it_behaves_like 'reporting a plain failure'
      end

      context 'with a server that lacks STARTTLS' do
        let(:error) { Net::SMTPUnsupportedCommand.new('STARTTLS is not supported on this server') }

        it_behaves_like 'reporting a plain failure'
      end

      context 'with a timeout' do
        let(:error) { Net::OpenTimeout.new('execution expired') }

        it_behaves_like 'reporting a plain failure'
      end

      context 'with a refused connection' do
        let(:error) { Errno::ECONNREFUSED.new }

        it_behaves_like 'reporting a plain failure'
      end

      context 'with a TLS error' do
        let(:error) { OpenSSL::SSL::SSLError.new('certificate verify failed') }

        it_behaves_like 'reporting a plain failure'
      end
    end

    context 'with a recipient' do
      let(:options) { { recipient: 'admin@example.com' } }

      it { is_expected.to eq(result: 'ok') }

      it 'sends the test mail to the recipient with its own text' do
        probe_result

        expect(Channel::EmailBuild).to have_received(:build).with(
          include(
            from: sender,
            to:   'admin@example.com',
            body: include('to this address').and(not_include('external')),
          ),
          anything,
        )
      end

      context 'when the server refuses the test mail' do
        let(:error) { smtp_error(Net::SMTPFatalError, '550 5.1.1 User unknown') }

        it_behaves_like 'reporting a refusal'
      end

      context 'when the recipient is blank' do
        let(:options) { { recipient: '' } }

        it 'sends the test mail to the external address' do
          probe_result

          expect(Channel::EmailBuild).to have_received(:build).with(
            include(
              to:   'verify-external-smtp-sending@discard.zammad.org',
              body: include('to an external address'),
            ),
            anything,
          )
        end
      end
    end

    context 'when a BCC of the system is set' do
      before do
        Setting.set('system_bcc', 'archive@example.org')
      end

      it 'adds it to the test mail' do
        probe_result

        expect(Channel::EmailBuild).to have_received(:build).with(include(bcc: 'archive@example.org'), anything)
      end

      context 'when the caller asks for a test mail without it' do
        let(:options) { { recipient: 'admin@example.com', system_bcc: false } }

        it 'sends the test mail to the recipient only' do
          probe_result

          expect(Channel::EmailBuild).to have_received(:build).with(include(to: 'admin@example.com').and(not_include(:bcc)), anything)
        end
      end
    end

    context 'with a subject' do
      let(:arguments) { ['#1234'] }

      it 'sends the test mail to the sender for the roundtrip' do
        probe_result

        expect(Channel::EmailBuild).to have_received(:build).with(
          include(
            :from                   => sender,
            :to                     => sender,
            :subject                => 'Zammad Getting started Test Email #1234',
            'X-Zammad-Test-Message' => '#1234',
          ),
          anything,
        )
      end

      context 'with a recipient' do
        let(:options) { { recipient: 'admin@example.com' } }

        it 'raises an error' do
          expect { probe_result }.to raise_error(ArgumentError)
        end
      end
    end

    context 'with the sendmail adapter' do
      let(:adapter) { 'sendmail' }
      let(:error)   { RuntimeError.new('sendmail exited with 1') }

      it_behaves_like 'reporting a plain failure'

      context 'without options' do
        let(:outbound_params) { { adapter: adapter } }

        it_behaves_like 'reporting a plain failure'
      end
    end
  end
end
