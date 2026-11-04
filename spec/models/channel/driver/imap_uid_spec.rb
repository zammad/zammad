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

  before do
    allow(driver).to receive(:setup_connection) do
      driver.instance_variable_set(:@imap, imap)
    end
    allow(imap).to receive(:capabilities).and_return(capabilities)
    allow(Channel::Driver::BaseEmailInbound::MessageValidator).to receive(:new).and_return(validator)

    allow(imap).to receive(:sort) { messages.each_index.map { |index| index + 1 } }
    allow(imap).to receive(:search) { messages.each_index.map { |index| index + 1 } }
    allow(imap).to receive(:uid_sort) { messages.pluck(:uid) }
    allow(imap).to receive(:uid_search) { messages.pluck(:uid) }

    %i[fetch uid_fetch].each do |command|
      allow(imap).to receive(command) do |id, attributes|
        message = command == :uid_fetch ? messages.find { |entry| entry[:uid] == id } : messages[id - 1]
        next [] if !message

        response = [Net::IMAP::FetchData.new(messages.index(message) + 1, {
                                               'RFC822.SIZE'   => message[:body].bytesize,
                                               'FLAGS'         => message[:flags].dup,
                                               'INTERNALDATE'  => Time.current,
                                               'RFC822.HEADER' => "Subject: #{message[:body]}\r\n",
                                               'RFC822'        => message[:body],
                                             })]
        imap.expunge if expunge_after_metadata && attributes.is_a?(Array)
        response
      end
    end

    %i[store uid_store].each do |command|
      allow(imap).to receive(command) do |id, _operation, flags|
        message = command == :uid_store ? messages.find { |entry| entry[:uid] == id } : messages[id - 1]
        message[:flags].concat(flags) if message
      end
    end

    allow(imap).to receive(:expunge) { messages.reject! { |message| message[:flags].include?(:Deleted) } }
    allow(driver).to receive(:process) do |_channel, body, _trusted|
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
  end

  describe '#verify_transport' do
    it 'deletes only the verification message identified by UID' do
      result = driver.verify_transport({}, 'second message')

      expect(result).to include(result: 'ok')
      expect(messages.pluck(:uid)).to eq([20])
    end
  end
end
