# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Driver::Imap, integration: true, required_envs: %w[MAIL_SERVER MAIL_ADDRESS MAIL_PASS MAIL_ADDRESS_ASCII MAIL_PASS_ASCII] do
  # https://github.com/zammad/zammad/issues/2964
  context 'when connecting with a ASCII 8-Bit password' do
    it 'succeeds' do

      params = {
        host:       ENV['MAIL_SERVER'],
        user:       ENV['MAIL_ADDRESS_ASCII'],
        password:   ENV['MAIL_PASS_ASCII'],
        ssl_verify: false,
      }

      result = described_class.new.check_configuration(params)

      expect(result[:result]).to eq 'ok'
    end
  end

  describe '.parse_rfc822_headers' do
    it 'parses simple header' do
      expect(described_class.parse_rfc822_headers('Key: Value')).to have_key('Key').and(have_value('Value'))
    end

    it 'parses header with no white space' do
      expect(described_class.parse_rfc822_headers('Key:Value')).to have_key('Key').and(have_value('Value'))
    end

    it 'parses multiline header' do
      expect(described_class.parse_rfc822_headers("Key: Value\r\n2nd-key: 2nd-value"))
        .to have_key('Key').and(have_value('Value')).and(have_key('2nd-key')).and(have_value('2nd-value'))
    end

    it 'parses value with semicolons' do
      expect(described_class.parse_rfc822_headers('Key: Val:ue')).to have_key('Key').and(have_value('Val:ue'))
    end

    it 'parses key-only lines' do
      expect(described_class.parse_rfc822_headers('Key')).to have_key('Key')
    end

    it 'handles empty line' do
      expect { described_class.parse_rfc822_headers("Key: Value\r\n") }.not_to raise_error
    end

    it 'handles tabbed value' do
      expect(described_class.parse_rfc822_headers("Key: \r\n\tValue")).to have_key('Key').and(have_value('Value'))
    end
  end

  describe '.extract_rfc822_headers' do
    it 'extracts header' do
      object = Net::IMAP::FetchData.new :id, { 'RFC822.HEADER' => 'Key: Value' }
      expect(described_class.extract_rfc822_headers(object)).to have_key('Key').and(have_value('Value'))
    end

    it 'returns nil when header attribute is missing' do
      object = Net::IMAP::FetchData.new :id, { 'Another' => 'Key: Value' }
      expect(described_class.extract_rfc822_headers(object)).to be_nil
    end

    it 'does not raise error when given nil' do
      expect { described_class.extract_rfc822_headers(nil) }.not_to raise_error
    end
  end

  shared_context 'with channel and server configuration' do
    let(:folder) { "imap_spec-#{SecureRandom.uuid}" }

    let(:server_address) { ENV['MAIL_SERVER'] }
    let(:server_login)    { ENV['MAIL_ADDRESS'] }
    let(:server_password) { ENV['MAIL_PASS'] }
    let(:email_address)   { create(:email_address, name: 'Zammad Helpdesk', email: "some-zammad-#{ENV['MAIL_ADDRESS']}") }
    let(:group)           { create(:group, email_address: email_address) }
    let(:inbound_options) do
      {
        adapter: 'imap',
        options: {
          host:           ENV['MAIL_SERVER'],
          user:           ENV['MAIL_ADDRESS'],
          password:       server_password,
          ssl:            'ssl',
          ssl_verify:     false,
          folder:         folder,
          keep_on_server: false,
        }
      }
    end
    let(:outbound_options) do
      {
        adapter: 'smtp',
        options: {
          host:       server_address,
          port:       25,
          start_tls:  true,
          ssl_verify: false,
          user:       server_login,
          password:   server_password,
          email:      email_address.email
        },
      }
    end
    let(:channel) do
      create(:email_channel, group: group, inbound: inbound_options, outbound: outbound_options).tap do |channel|
        email_address.channel = channel
        email_address.save!
      end
    end

    let(:imap) { Net::IMAP.new(server_address, port: 993, ssl: { verify_mode: OpenSSL::SSL::VERIFY_NONE }).tap { |imap| imap.login(server_login, server_password) } }
  end

  describe '#fetch', :aggregate_failures do
    include_context 'with channel and server configuration'

    def purge_inbox
      imap.select('inbox')
      imap.sort(['DATE'], ['ALL'], 'US-ASCII').each do |msg|
        imap.store(msg, '+FLAGS', [:Deleted])
      end
      imap.expunge
    end

    before do
      purge_inbox
      imap.create(Net::IMAP.encode_utf7(folder))
      imap.select(Net::IMAP.encode_utf7(folder))
    end

    after do
      imap.delete(Net::IMAP.encode_utf7(folder))
    end

    context 'when fetching regular emails' do
      let(:email1) do
        <<~EMAIL.gsub(%r{\n}, "\r\n")
          Subject: hello1
          From: shugo@example.com
          To: shugo@example.com
          Message-ID: <some1@example_keep_on_server>

          hello world
        EMAIL
      end
      let(:email2) do
        <<~EMAIL.gsub(%r{\n}, "\r\n")
          Subject: hello2
          From: shugo@example.com
          To: shugo@example.com
          Message-ID: <some2@example_keep_on_server>

          hello world
        EMAIL
      end

      context 'with keep_on_server flag' do
        let(:inbound_options) do
          {
            adapter: 'imap',
            options: {
              host:           ENV['MAIL_SERVER'],
              user:           ENV['MAIL_ADDRESS'],
              password:       server_password,
              ssl:            'ssl',
              ssl_verify:     false,
              folder:         folder,
              keep_on_server: true,
            }
          }
        end

        it 'handles messages correctly' do # rubocop:disable RSpec/ExampleLength

          imap.append(folder, email1, [], Time.zone.now)

          # verify if message is still on server
          message_ids = imap.sort(['DATE'], ['ALL'], 'US-ASCII')
          expect(message_ids.count).to be(1)

          message_meta = imap.fetch(1, ['FLAGS'])[0].attr
          expect(message_meta['FLAGS']).not_to include(:Seen)

          # fetch messages - will import
          expect { channel.fetch(true) }.to change(Ticket::Article, :count)

          # verify if message is still on server
          message_ids = imap.sort(['DATE'], ['ALL'], 'US-ASCII')
          expect(message_ids.count).to be(1)

          # message now has :seen flag
          message_meta = imap.fetch(1, ['RFC822.HEADER', 'FLAGS'])[0].attr
          expect(message_meta['FLAGS']).to include(:Seen)

          # fetch messages - will not import
          expect { channel.fetch(true) }.not_to change(Ticket::Article, :count)
          expect(channel.reload).to have_attributes(status_in: 'ok')

          # verify if message is still on server
          message_ids = imap.sort(['DATE'], ['ALL'], 'US-ASCII')
          expect(message_ids.count).to be(1)

          # put unseen message in it
          imap.append(folder, email2, [], Time.zone.now)

          message_meta = imap.fetch(1, ['FLAGS'])[0].attr
          expect(message_meta['FLAGS']).to include(:Seen)
          message_meta = imap.fetch(2, ['FLAGS'])[0].attr
          expect(message_meta['FLAGS']).not_to include(:Seen)

          # fetch messages - will import new
          expect { channel.fetch(true) }.to change(Ticket::Article, :count)

          # verify if message is still on server
          message_ids = imap.sort(['DATE'], ['ALL'], 'US-ASCII')
          expect(message_ids.count).to be(2)

          message_meta = imap.fetch(1, ['FLAGS'])[0].attr
          expect(message_meta['FLAGS']).to include(:Seen)
          message_meta = imap.fetch(2, ['FLAGS'])[0].attr
          expect(message_meta['FLAGS']).to include(:Seen)

          # set messages to not seen
          imap.store(1, '-FLAGS', [:Seen])
          imap.store(2, '-FLAGS', [:Seen])

          # fetch messages - will still not import
          expect { channel.fetch(true) }.not_to change(Ticket::Article, :count)
          expect(channel.reload).to have_attributes(status_in: 'ok')
        end
      end

      context 'without keep_on_server flag' do

        it 'handles messages correctly' do

          imap.append(folder, email1, [], Time.zone.now)

          # verify if message is still on server
          message_ids = imap.sort(['DATE'], ['ALL'], 'US-ASCII')
          expect(message_ids.count).to be(1)

          message_meta = imap.fetch(1, ['FLAGS'])[0].attr
          expect(message_meta['FLAGS']).not_to include(:Seen)

          # fetch messages - will import
          expect { channel.fetch(true) }.to change(Ticket::Article, :count)

          # verify if message is still on server
          message_ids = imap.sort(['DATE'], ['ALL'], 'US-ASCII')
          expect(message_ids.count).to be(1)

          message_meta = imap.fetch(1, ['FLAGS'])[0].attr
          expect(message_meta['FLAGS']).to include(:Seen, :Deleted)

          # put unseen message in it
          imap.append(folder, email2, [], Time.zone.now)

          # verify if message is still on server
          message_ids = imap.sort(['DATE'], ['ALL'], 'US-ASCII')
          expect(message_ids.count).to be(1)

          message_meta = imap.fetch(1, ['FLAGS'])[0].attr
          expect(message_meta['FLAGS']).not_to include(:Seen)

          # fetch messages - will import
          expect { channel.fetch(true) }.to change(Ticket::Article, :count)

          # verify if message is still on server
          message_ids = imap.sort(['DATE'], ['ALL'], 'US-ASCII')
          expect(message_ids.count).to be(1)

          message_meta = imap.fetch(1, ['FLAGS'])[0].attr
          expect(message_meta['FLAGS']).to include(:Seen)
        end

        it 'handles already deleted message correctly' do
          imap.append(folder, email1, [:Deleted], Time.zone.now)
          imap.append(folder, email2, [], Time.zone.now)

          expect { channel.fetch(true) }.to change(Ticket, :count).by(1)
          expect(channel.reload).to have_attributes(status_in: 'ok')
        end
      end

      context 'when folder name contains special characters' do
        let(:folder) { 'uat-bk-rsc-20250130-!"§$%&()=?ß`\ß_<' }

        it 'handles messages correctly' do

          imap.append(Net::IMAP.encode_utf7(folder), email1, [], Time.zone.now)

          # verify if message is still on server
          message_ids = imap.sort(['DATE'], ['ALL'], 'US-ASCII')
          expect(message_ids.count).to be(1)

          # fetch messages - will import
          expect { channel.fetch(true) }.to change(Ticket::Article, :count)

        end
      end
    end

    context 'when fetching oversized emails' do
      let(:sender_email_address) { ENV['MAIL_ADDRESS'] }
      let(:cid)                  { SecureRandom.uuid.tr('-', '.') }
      let(:oversized_email) do
        <<~OVERSIZED_EMAIL.gsub(%r{\n}, "\r\n")
          Subject: Oversized Email Message
          From: Max Mustermann <#{sender_email_address}>
          To: shugo@example.com
          Message-ID: <#{cid}@zammad.test.com>

          Oversized Email Message Body #{'#' * 120_000}
        OVERSIZED_EMAIL
      end
      let(:oversized_email_md5) { Digest::MD5.hexdigest(oversized_email) }
      let(:oversized_email_size) { format('%<MB>.2f', MB: oversized_email.size.to_f / 1024 / 1024) }

      def fetch_oversized_email
        imap.append(folder, oversized_email, [], Time.zone.now)
        channel.fetch(true)
      end

      context 'with email reply' do
        before do
          Setting.set('postmaster_max_size', 0.1)
          fetch_oversized_email
        end

        let(:oversized_email_reply) do
          imap.select('inbox')
          5.times do |i|
            sleep i
            msg = imap.sort(['DATE'], ['ALL'], 'US-ASCII').first
            if msg
              return imap.fetch(msg, 'RFC822')[0].attr['RFC822']
            end
          end
          nil
        end

        let(:parsed_oversized_email_reply) do
          Channel::EmailParser.new.parse(oversized_email_reply)
        end

        it 'creates email reply correctly' do
          # verify that a postmaster response email has been sent to the sender
          expect(oversized_email_reply).to be_present

          # parse the reply mail and verify the various headers
          expect(parsed_oversized_email_reply).to include(
            {
              from_email: email_address.email,
              subject: '[undeliverable] Message too large',
              'references' => "<#{cid}@zammad.test.com>",
              'in-reply-to' => "<#{cid}@zammad.test.com>",
            }
          )

          # verify the reply mail body content
          expect(parsed_oversized_email_reply[:body]).to match(%r{^Dear Max Mustermann.*Oversized Email Message.*#{oversized_email_size} MB.*0.1 MB.*#{Setting.get('fqdn')}}sm)

          # check if original mail got removed
          imap.select(folder)
          expect(imap.sort(['DATE'], ['ALL'], 'US-ASCII')).to be_empty
        end
      end

      context 'without email reply' do
        before do
          Setting.set('postmaster_max_size', 0.1)
          Setting.set('postmaster_send_reject_if_mail_too_large', false)
          fetch_oversized_email
        end

        it 'does not create email reply' do

          # verify that no postmaster response email has been sent
          imap.select('inbox')
          sleep 1
          expect(imap.sort(['DATE'], ['ALL'], 'US-ASCII').count).to be_zero

          # check that original mail is still there
          imap.select(folder)
          expect(imap.sort(['DATE'], ['ALL'], 'US-ASCII').count).to be(1)

          # check that channel has correct error message
          expect(channel.reload).to have_attributes(
            status_in:   'error',
            last_log_in: include('because message is too large')
          )
        end
      end
    end

    context 'when fetching a verify message' do
      it 'skips verify message without errors' do
        imap.append folder, mock_a_message(verify: true)

        expect { channel.fetch(true) }.not_to change(Ticket, :count)
        expect(channel.reload.status_in).to eq('ok')
      end
    end
  end

  describe '.fetch_message_body_key' do
    context 'with icloud mail server' do
      let(:host) { 'imap.mail.me.com' }

      it 'fetches mails with BODY field' do
        expect(described_class.new.fetch_message_body_key({ 'host' => host })).to eq('BODY[]')
      end
    end

    context 'with another mail server' do
      let(:host) { 'any.server.com' }

      it 'fetches mails with RFC822 field' do
        expect(described_class.new.fetch_message_body_key({ 'host' => host })).to eq('RFC822')
      end
    end
  end

  describe '#check_configuration' do
    include_context 'with channel and server configuration'

    before do
      imap.create(folder)
      imap.select(folder)
    end

    after do
      imap.delete(folder)
    end

    context 'when no messages exist' do
      it 'finds no content messages' do
        response = described_class
          .new
          .check_configuration(inbound_options[:options])

        expect(response).to include(
          result:           'ok',
          content_messages: be_zero,
        )
      end
    end

    context 'when a verify message exist' do
      it 'finds no content messages' do
        imap.append folder, mock_a_message(verify: true)

        response = described_class
          .new
          .check_configuration(inbound_options[:options])

        expect(response).to include(
          result:           'ok',
          content_messages: be_zero,
        )
      end
    end

    context 'when some content messages exist' do
      it 'finds content messages' do
        3.times { imap.append folder, mock_a_message }

        response = described_class
          .new
          .check_configuration(inbound_options[:options])

        expect(response).to include(
          result:           'ok',
          content_messages: 3,
        )
      end
    end

    context 'when a verify and a content message exists' do
      it 'finds content messages' do
        imap.append folder, mock_a_message(verify: true)
        imap.append folder, mock_a_message

        response = described_class
          .new
          .check_configuration(inbound_options[:options])

        expect(response).to include(
          result:           'ok',
          content_messages: 2,
        )
      end
    end
  end

  describe '#verify_transport' do
    include_context 'with channel and server configuration'

    before do
      imap.create(folder)
      imap.select(folder)
    end

    after do
      imap.delete(folder)
    end

    let(:verify_message) { Faker::Lorem.unique.sentence }

    context 'when no messages exist' do
      it 'returns falsy response' do
        response = described_class
          .new
          .verify_transport(inbound_options[:options], verify_message)

        expect(response).to include(result: 'verify not ok')
      end
    end

    context 'when a content message exists' do
      it 'returns falsy response' do
        imap.append folder, mock_a_message

        response = described_class
          .new
          .verify_transport(inbound_options[:options], verify_message)

        expect(response).to include(result: 'verify not ok')
      end
    end

    context 'when a verify message exists' do
      before do
        imap.append folder, mock_a_message(verify: verify_message)
      end

      it 'returns truthy response with the correct verify string' do
        response = described_class
          .new
          .verify_transport(inbound_options[:options], verify_message)

        expect(response).to include(result: 'ok')
      end

      it 'deletes the correct verify message' do
        described_class
          .new
          .verify_transport(inbound_options[:options], verify_message)

        message_ids = imap.sort(['DATE'], ['ALL'], 'US-ASCII')
        message_meta = imap.fetch(message_ids.first, ['FLAGS'])[0].attr
        expect(message_meta['FLAGS']).to include(:Deleted)
      end

      it 'returns falsy response with the wrong verify string' do
        response = described_class
          .new
          .verify_transport(inbound_options[:options], 'another message')

        expect(response).to include(result: 'verify not ok')
      end

      it 'does not delete not matching verify message' do
        described_class
          .new
          .verify_transport(inbound_options[:options], 'another message')

        message_ids = imap.sort(['DATE'], ['ALL'], 'US-ASCII')
        message_meta = imap.fetch(message_ids.first, ['FLAGS'])[0].attr
        expect(message_meta['FLAGS']).not_to include(:Deleted)
      end
    end

    context 'when a content and a verify message exists' do
      it 'returns truthy response' do
        imap.append folder, mock_a_message(verify: verify_message)
        imap.append folder, mock_a_message

        response = described_class
          .new
          .verify_transport(inbound_options[:options], verify_message)

        expect(response).to include(result: 'ok')
      end
    end
  end

  def mock_a_message(subject: nil, verify: false)
    attrs = {
      from:         Faker::Internet.unique.email,
      to:           Faker::Internet.unique.email,
      body:         Faker::Lorem.sentence,
      subject:      verify.presence || subject.presence || Faker::Lorem.word,
      content_type: 'text/html',
    }

    if verify.present?
      attrs[:'X-Zammad-Ignore'] = 'true'
      attrs[:'X-Zammad-Verify'] = 'true'
      attrs[:'X-Zammad-Verify-Time'] = Time.current.iso8601
    end

    Channel::EmailBuild.build(**attrs).to_s
  end
end
