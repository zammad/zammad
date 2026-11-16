# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Driver::Imap, :aggregate_failures do
  subject(:driver) { described_class.new }

  let(:imap)         { instance_double(Net::IMAP, disconnect: nil) }
  let(:capabilities) { ['SORT'] }
  let(:options)      { { keep_on_server: false } }
  let(:validator)    { instance_double(Channel::Driver::BaseEmailInbound::MessageValidator, fresh_verify_message?: false, already_imported?: false, too_large?: false) }
  let(:messages) do
    [
      { uid: 10, flags: [:Deleted], body: 'previously deleted' },
      { uid: 20, flags: [], body: 'first message' },
      { uid: 30, flags: [], body: 'second message' },
    ]
  end
  let(:processed) { [] }
  let(:expunge_after_metadata) { false }
  let(:expunged_before_body)   { nil }
  let(:unsolicited_response)   { false }
  let(:unparsable_uid)         { nil }
  let(:split_responses)        { false }
  let(:connection)             { { closed: false } }
  let(:failing_body)           { nil }

  before do
    allow(driver).to receive(:setup_connection) do
      connection[:closed] = false
      driver.instance_variable_set(:@imap, imap)
    end
    allow(imap).to receive(:capabilities).and_return(capabilities)
    allow(Channel::Driver::BaseEmailInbound::MessageValidator).to receive(:new).and_return(validator)

    allow(imap).to receive(:uid_sort) { messages.pluck(:uid) }
    allow(imap).to receive(:uid_search) { messages.pluck(:uid) }

    allow(imap).to receive(:uid_fetch) do |uid, attributes|
      raise IOError, 'closed stream' if connection[:closed]

      message    = messages.find { |entry| entry[:uid] == uid }
      body_fetch = attributes.include?('RFC822')
      next [] if !message

      # Like net-imap, which closes the connection when it cannot parse a response.
      if uid == unparsable_uid && attributes.include?('RFC822.SIZE')
        connection[:closed] = true
        raise Net::IMAP::ResponseParseError, 'unknown token - "BODYSTRUCTURE"'
      end

      if uid == expunged_before_body && body_fetch
        messages.delete(message)
        next []
      end

      response = [Net::IMAP::FetchData.new(messages.index(message) + 1, {
                                             'UID'           => message[:uid],
                                             'RFC822.SIZE'   => message[:body].bytesize,
                                             'FLAGS'         => message[:flags].dup,
                                             'INTERNALDATE'  => Time.current,
                                             'RFC822.HEADER' => "Subject: #{message[:body]}\r\n",
                                             'RFC822'        => message[:body],
                                           })]
      if body_fetch
        message[:flags] |= [:Seen]
      elsif expunge_after_metadata
        imap.expunge
      end

      # The server reports the implicit \Seen of the body fetch in a response of its own.
      response.unshift(Net::IMAP::FetchData.new(response.first.seqno, { 'UID' => uid, 'FLAGS' => [:Seen] })) if split_responses && body_fetch

      # Another session changed the flags of the first message while this command ran.
      response.unshift(Net::IMAP::FetchData.new(1, { 'FLAGS' => [:Seen] })) if unsolicited_response
      response
    end

    allow(imap).to receive(:uid_store) do |uid, operation, flags|
      raise IOError, 'closed stream' if connection[:closed]

      message = messages.find { |entry| entry[:uid] == uid }
      next if !message

      if operation.start_with?('-')
        message[:flags] -= flags
      else
        message[:flags] |= flags
      end
    end

    allow(imap).to receive(:expunge) do
      raise IOError, 'closed stream' if connection[:closed]

      messages.reject! { |message| message[:flags].include?(:Deleted) }
    end
    allow(driver).to receive(:process) do |_channel, body, _trusted|
      raise 'processing failed' if body == failing_body

      processed << body
      # Another IMAP session can expunge between fetching a body and storing its flags.
      imap.expunge
    end
  end

  shared_examples 'a fetch with concurrent expunges' do
    it 'imports every remaining message before deleting it' do
      result = driver.fetch(options, nil)

      expect(processed).to eq(['first message', 'second message'])
      expect(result).to include(result: 'ok', fetched: 2)
      expect(messages).to be_empty
    end

    context 'when keeping messages on the server' do
      let(:options) { { keep_on_server: true } }

      it 'marks the imported messages as seen despite sequence number changes' do
        result = driver.fetch(options, nil)

        expect(processed).to eq(['first message', 'second message'])
        expect(result).to include(result: 'ok', fetched: 2)
        expect(messages.pluck(:uid)).to eq([20, 30])
        expect(messages.pluck(:flags)).to eq([[:Seen], [:Seen]])
      end
    end
  end

  context 'when SORT is available' do
    include_examples 'a fetch with concurrent expunges'
  end

  context 'when SORT is unavailable' do
    let(:capabilities) { [] }

    include_examples 'a fetch with concurrent expunges'
  end

  context 'when another session expunges between metadata and body retrieval' do
    let(:expunge_after_metadata) { true }

    include_examples 'a fetch with concurrent expunges'
  end

  context 'when the metadata of a message cannot be parsed' do
    let(:unparsable_uid) { 20 }

    it 'reports the message to be removed and imports the others on a new connection' do
      result = driver.fetch(options, nil)

      expect(result).to include(result: 'error')
      expect(result[:notice]).to include('One of your incoming emails could not be imported (unknown token')
      expect(processed).to eq(['second message'])
      expect(driver).to have_received(:setup_connection).twice
    end

    context 'when it is the last message' do
      let(:unparsable_uid) { 30 }

      it 'still expunges the imported messages on a new connection' do
        driver.fetch(options, nil)

        expect(processed).to eq(['first message'])
        expect(messages.pluck(:uid)).to eq([30])
      end
    end
  end

  context 'when the server splits the data of a message across several FETCH responses' do
    let(:split_responses) { true }

    include_examples 'a fetch with concurrent expunges'
  end

  it 'requests the UID explicitly in every fetch' do
    driver.fetch(options, nil)

    expect(imap).to have_received(:uid_fetch).with(20, include('RFC822.SIZE', 'UID'))
    expect(imap).to have_received(:uid_fetch).with(20, include('RFC822', 'UID'))
  end

  context 'when the server sends an unsolicited FETCH response for another message first' do
    let(:unsolicited_response) { true }

    include_examples 'a fetch with concurrent expunges'
  end

  context 'when a message is too large and is not rejected while keeping messages on the server' do
    let(:options) { { keep_on_server: true } }

    before do
      Setting.set('postmaster_send_reject_if_mail_too_large', false)
      allow(validator).to receive(:too_large?).and_return([30.0, 20.0])
    end

    it 'does not fetch the body, so the message stays unread and the error is raised again on the next run' do
      expect { driver.fetch(options, nil) }.to raise_error(RuntimeError, %r{too large})

      expect(processed).to be_empty
      expect(messages.pluck(:flags)).to eq([[:Deleted], [], []])
    end
  end

  context 'when another session expunges a message between its metadata and body retrieval' do
    let(:expunged_before_body) { 20 }

    it 'skips the vanished message and imports the others' do
      result = driver.fetch(options, nil)

      expect(processed).to eq(['second message'])
      expect(result).to include(result: 'ok', fetched: 1)
      expect(messages).to be_empty
    end
  end

  context 'when a message cannot be processed while keeping messages on the server' do
    let(:options)      { { keep_on_server: true } }
    let(:failing_body) { 'second message' }

    it 'marks the failed message unread again by its UID' do
      driver.fetch(options, nil)

      expect(imap).to have_received(:uid_store).with(30, '-FLAGS.SILENT', [:Seen])
      expect(messages.find { |message| message[:uid] == 30 }[:flags]).not_to include(:Seen)
    end
  end

  context 'when messages have already been imported' do
    let(:options) { { keep_on_server: true } }

    before do
      allow(validator).to receive(:already_imported?).and_return(true)
    end

    it 'marks those messages as seen without importing them again' do
      result = driver.fetch(options, nil)

      expect(processed).to be_empty
      expect(result).to include(result: 'ok', fetched: 0)
      expect(messages.pluck(:flags)).to eq([[:Deleted], [:Seen], [:Seen]])
    end
  end

  describe '#check_configuration' do
    it 'checks the headers of messages identified by UID' do
      allow(validator).to receive_messages(verify_message?: false, ignore?: false)

      expect(driver.check_configuration({})).to include(result: 'ok', content_messages: 3)
      expect(Channel::Driver::BaseEmailInbound::MessageValidator).to have_received(:new).with({ 'Subject' => 'previously deleted' })
    end

    context 'when a listed message is expunged before its headers are fetched' do
      before do
        allow(imap).to receive(:uid_sort).and_return([99] + messages.pluck(:uid))
      end

      it 'skips the vanished message' do
        allow(validator).to receive_messages(verify_message?: false, ignore?: false)

        expect(driver.check_configuration({})).to include(result: 'ok')
        expect(Channel::Driver::BaseEmailInbound::MessageValidator).to have_received(:new).with({ 'Subject' => 'previously deleted' })
      end
    end
  end

  describe '#verify_transport' do
    it 'deletes only the verification message identified by UID' do
      result = driver.verify_transport({}, 'second message')

      expect(result).to include(result: 'ok')
      expect(messages.pluck(:uid)).to eq([20])
    end

    %w[UIDPLUS IMAP4rev2].each do |capability|
      context "when the server announces #{capability}" do
        let(:capabilities) { ['SORT', capability] }

        before do
          allow(imap).to receive(:uid_expunge) { |uid| messages.reject! { |message| message[:uid] == uid } }
        end

        it 'removes only the verification message, not messages another client flagged as deleted' do
          result = driver.verify_transport({}, 'second message')

          expect(result).to include(result: 'ok')
          expect(messages.pluck(:uid)).to eq([10, 20])
          expect(imap).not_to have_received(:expunge)
        end
      end
    end

    context 'when a listed message is expunged before its headers are fetched' do
      before do
        # Listed last, so the reverse search for the verification message reaches it first.
        allow(imap).to receive(:uid_sort).and_return(messages.pluck(:uid) + [99])
      end

      it 'skips the vanished message and still finds the verification message' do
        result = driver.verify_transport({}, 'second message')

        expect(result).to include(result: 'ok')
        expect(messages.pluck(:uid)).to eq([20])
      end
    end
  end
end
