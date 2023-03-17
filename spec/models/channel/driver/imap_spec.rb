# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Driver::Imap, integration: true, required_envs: %w[MAIL_SERVER MAIL_ADDRESS MAIL_PASS MAIL_ADDRESS_ASCII MAIL_PASS_ASCII] do
  # https://github.com/zammad/zammad/issues/2964
  context 'when connecting with a ASCII 8-Bit password' do
    it 'succeeds' do

      params = {
        host:     ENV['MAIL_SERVER'],
        user:     ENV['MAIL_ADDRESS_ASCII'],
        password: ENV['MAIL_PASS_ASCII'],
      }

      result = described_class.new.fetch(params, nil, 'check')

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

  describe '.fetch', :aggregate_failures do
    let(:folder) { "imap_spec-#{SecureRandom.uuid}" }

    let(:server_address) { ENV['MAIL_SERVER'] }
    let(:server_login)    { ENV['MAIL_ADDRESS'] }
    let(:server_password) { ENV['MAIL_PASS'] }
    let(:email_address)   { create(:email_address, realname: 'Zammad Helpdesk', email: "some-zammad-#{ENV['MAIL_ADDRESS']}") }
    let(:group)           { create(:group, email_address: email_address) }
    let(:inbound_options) do
      {
        adapter: 'imap',
        options: {
          host:           ENV['MAIL_SERVER'],
          user:           ENV['MAIL_ADDRESS'],
          password:       server_password,
          ssl:            true,
          folder:         folder,
          keep_on_server: false,
        }
      }
    end
    let(:outbound_options) do
      {
        adapter: 'smtp',
        options: {
          host:      server_address,
          port:      25,
          start_tls: true,
          user:      server_login,
          password:  server_password,
          email:     email_address.email
        },
      }
    end
    let(:channel) do
      create(:email_channel, group: group, inbound: inbound_options, outbound: outbound_options).tap do |channel|
        email_address.channel = channel
        email_address.save!
      end
    end

    let(:imap) { Net::IMAP.new(server_address, 993, true, nil, false).tap { |imap| imap.login(server_login, server_password) } }

    let(:purge_inbox) do
      imap.select('inbox')
      imap.sort(['DATE'], ['ALL'], 'US-ASCII').each do |msg|
        imap.store(msg, '+FLAGS', [:Deleted])
      end
      imap.expunge
    end

    before do
      purge_inbox
      imap.create(folder)
      imap.select(folder)
    end

    after do
      imap.delete(folder)
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
              ssl:            true,
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
      let(:oversized_eml_folder) { Rails.root.join('tmp/oversized_mail') }
      let(:oversized_eml_file) do
        Dir.entries(oversized_eml_folder).grep(%r{^#{oversized_email_md5}\.eml$}).map { |path| oversized_eml_folder.join(path) }.last
      end

      let(:fetch_oversized_email) do
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
          # 1. verify that the oversized email has been saved locally to:
          # /tmp/oversized_mail/yyyy-mm-ddThh:mm:ss-:md5.eml
          expect(oversized_eml_file).to be_present

          # verify that the file is byte for byte identical to the sent message
          expect(File.read(oversized_eml_file)).to eq(oversized_email)

          # 2. verify that a postmaster response email has been sent to the sender
          expect(oversized_email_reply).to be_present

          # parse the reply mail and verify the various headers
          expect(parsed_oversized_email_reply).to include({
                                                            from_email: email_address.email,
            subject: '[undeliverable] Message too large',
            'references' => "<#{cid}@zammad.test.com>",
            'in-reply-to' => "<#{cid}@zammad.test.com>",
                                                          })

          # verify the reply mail body content
          expect(parsed_oversized_email_reply[:body]).to match(%r{^Dear Max Mustermann.*Oversized Email Message.*#{oversized_email_size} MB.*0.1 MB.*#{Setting.get('fqdn')}}sm)

          # 3. check if original mail got removed
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

          # 1. verify that email was not locally processed
          expect(oversized_eml_file).to be_nil

          # 2. verify that no postmaster response email has been sent
          imap.select('inbox')
          sleep 1
          expect(imap.sort(['DATE'], ['ALL'], 'US-ASCII').count).to be_zero

          # 3. check that original mail is still there
          imap.select(folder)
          expect(imap.sort(['DATE'], ['ALL'], 'US-ASCII').count).to be(1)
        end
      end
    end
  end
end
