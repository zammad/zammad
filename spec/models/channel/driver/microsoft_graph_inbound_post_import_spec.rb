# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Driver::MicrosoftGraphInbound, :aggregate_failures do
  subject(:driver) { described_class.new }

  let(:graph)     { instance_double(MicrosoftGraph) }
  let(:channel)   { build_stubbed(:channel) }
  let(:options)   { { user: 'mailbox@example.com', password: 'token', post_import_action: 'move', move_to_folder_id: 'destination' } }
  let(:validator) { instance_double(Channel::Driver::BaseEmailInbound::MessageValidator, fresh_verify_message?: false, too_large?: false) }

  before do
    allow(MicrosoftGraph).to receive(:new).and_return(graph)
    allow(graph).to receive(:get_message_folder_details).with('inbox').and_return({ id: 'source' })
    allow(graph).to receive(:get_message_folder_details).with('destination').and_return({ id: 'destination' })
    allow(graph).to receive_messages(list_messages: { items: [{ id: 'message' }], total_count: 1 }, get_message_basic_details: { headers: {}, size: 100 }, get_raw_message: 'mail', move_message: { id: 'moved' }, mark_message_as_read: nil, delete_message: nil)
    allow(Channel::Driver::BaseEmailInbound::MessageValidator).to receive(:new).and_return(validator)
    allow(validator).to receive(:already_imported?).with(true, channel).and_return(false)
    allow(driver).to receive(:process)
  end

  it 'imports before moving to the destination folder' do
    allow(graph).to receive(:move_message).with('message', 'destination') do
      expect(driver).to have_received(:process).with(channel, 'mail', false)
    end

    expect(driver.fetch(options, channel)).to include(result: 'ok', fetched: 1)
  end

  it 'retries a failed move without importing the message again' do
    allow(validator).to receive(:already_imported?).with(true, channel).and_return(false, true)
    allow(graph).to receive(:move_message).with('message', 'destination')
      .and_raise(MicrosoftGraph::ApiError.new({ code: 'ErrorAccessDenied', message: 'Denied' }))

    expect { driver.fetch(options, channel) }.to raise_error(MicrosoftGraph::ApiError)

    allow(graph).to receive(:move_message).with('message', 'destination').and_return({ id: 'moved' })
    expect(driver.fetch(options, channel)).to include(fetched: 0)
    expect(driver).to have_received(:process).once
  end

  it 'leaves the message untouched when the raw message cannot be fetched' do
    allow(graph).to receive(:get_raw_message).and_raise(MicrosoftGraph::ApiError.new({ code: 'ErrorAccessDenied', message: 'Denied' }))
    expect { driver.fetch(options, channel) }.to raise_error(MicrosoftGraph::ApiError)
    expect(graph).not_to have_received(:move_message)
  end

  it 'also fetches read messages when moving, even with the legacy keep option enabled' do
    driver.fetch(options.merge(keep_on_server: true), channel)
    expect(graph).to have_received(:list_messages).with(unread_only: false, folder_id: nil, follow_pagination: false)
  end

  it 'rejects a missing destination before importing' do
    expect { driver.fetch(options.except(:move_to_folder_id), channel) }.to raise_error(Exceptions::UnprocessableContent)
    expect(driver).not_to have_received(:process)
  end

  it 'rejects the inbox id as the destination even when the source uses the inbox alias' do
    allow(graph).to receive(:get_message_folder_details).with('destination').and_return({ id: 'source' })

    expect { driver.fetch(options, channel) }.to raise_error(Exceptions::UnprocessableContent)
    expect(driver).not_to have_received(:process)
  end

  it 'rejects unknown actions' do
    expect { driver.fetch(options.merge(post_import_action: 'unknown'), channel) }.to raise_error(Exceptions::UnprocessableContent)
  end

  it 'preserves Graph error details when the destination folder cannot be accessed' do
    allow(graph).to receive(:get_message_folder_details).with('destination')
      .and_raise(MicrosoftGraph::ApiError.new({ code: 'ErrorItemNotFound', message: 'Mailbox access denied' }))

    expect { driver.fetch(options, channel) }
      .to raise_error('Microsoft Graph email folder does not exist: destination. Mailbox access denied (ErrorItemNotFound)')
    expect(driver).not_to have_received(:process)
    expect(graph).not_to have_received(:move_message)
  end

  it 'uses the real Message-ID lookup to retry cleanup of an imported message' do
    allow(Channel::Driver::BaseEmailInbound::MessageValidator).to receive(:new).and_call_original
    allow(graph).to receive_messages(get_message_basic_details: { headers: { 'Message-ID' => '<retry@example.com>' }, size: 100 }, move_message: { id: 'moved' })
    ticket = create(:ticket, preferences: { channel_id: channel.id })
    create(:ticket_article, ticket: ticket, message_id: '<retry@example.com>')

    allow(graph).to receive(:move_message).and_raise(MicrosoftGraph::ApiError.new({ code: 'ErrorAccessDenied', message: 'Denied' }))
    expect { driver.fetch(options, channel) }.to raise_error(MicrosoftGraph::ApiError)
    allow(graph).to receive(:move_message).and_return({ id: 'moved' })

    expect(driver.fetch(options, channel)).to include(fetched: 0)
    expect(driver).not_to have_received(:process)
    expect(graph).to have_received(:move_message).with('message', 'destination').twice
  end

  it 'does not move fresh verification messages' do
    allow(validator).to receive(:fresh_verify_message?).and_return(true)
    expect(driver.fetch(options, channel)).to include(fetched: 0)
    expect(graph).not_to have_received(:move_message)
  end

  it 'moves oversized messages after storing a rejection' do
    allow(validator).to receive(:too_large?).and_return([20, 10])
    Setting.set('postmaster_send_reject_if_mail_too_large', true)
    allow(driver).to receive(:process_oversized_mail)
    driver.fetch(options, channel)

    expect(driver).to have_received(:process_oversized_mail).with(channel, 'mail')
    expect(graph).to have_received(:move_message)
  end

  it 'leaves oversized messages untouched when rejection is disabled' do
    allow(validator).to receive(:too_large?).and_return([20, 10])
    Setting.set('postmaster_send_reject_if_mail_too_large', false)

    expect { driver.fetch(options, channel) }.to raise_error(%r{too large})
    expect(graph).not_to have_received(:move_message)
  end

  context 'with legacy options' do
    before do
      allow(validator).to receive(:already_imported?).and_return(false)
    end

    it 'still marks already-imported messages as read' do
      allow(validator).to receive(:already_imported?).and_return(true)
      driver.fetch(options.except(:post_import_action, :move_to_folder_id).merge(keep_on_server: true), channel)

      expect(graph).to have_received(:mark_message_as_read).with('message')
      expect(driver).not_to have_received(:process)
    end

    it 'marks messages as read when keep on server is enabled' do
      driver.fetch(options.except(:post_import_action, :move_to_folder_id).merge(keep_on_server: 'true'), channel)
      expect(graph).to have_received(:mark_message_as_read).with('message')
    end

    it 'deletes messages when keep on server is disabled' do
      driver.fetch(options.except(:post_import_action, :move_to_folder_id).merge(keep_on_server: 'false'), channel)
      expect(graph).to have_received(:delete_message).with('message')
    end
  end
end
