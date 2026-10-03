# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Driver::MicrosoftGraphInbound, :aggregate_failures do
  subject(:driver) { described_class.new }

  let(:graph)     { instance_double(MicrosoftGraph) }
  let(:channel)   { create(:channel, options: { inbound: { options: options } }) }
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

  it 'imports a distinct message even when its Message-ID already exists' do
    allow(Channel::Driver::BaseEmailInbound::MessageValidator).to receive(:new).and_call_original
    allow(graph).to receive(:get_message_basic_details).and_return({ headers: { 'Message-ID' => '<reused@example.com>' }, size: 100 })
    ticket = create(:ticket, preferences: { channel_id: channel.id })
    article = create(:ticket_article, ticket: ticket, message_id: '<reused@example.com>')
    article.save_as_raw('different original body and attachment')

    driver.fetch(options, channel)

    expect(graph).to have_received(:get_raw_message).with('message')
    expect(driver).to have_received(:process).with(channel, 'mail', false)
  end

  it 'stores a real colliding message and retries its move without a second article' do
    raw = "From: sender@example.com\r\nTo: mailbox@example.com\r\nSubject: Retry\r\nMessage-ID: <collision@example.com>\r\nContent-Type: text/plain; charset=UTF-8\r\n\r\nDistinct body"
    ticket = create(:ticket, preferences: { channel_id: channel.id })
    create(:ticket_article, ticket: ticket, message_id: '<collision@example.com>').save_as_raw('Original content')
    allow(driver).to receive(:process).and_call_original
    allow(graph).to receive_messages(get_raw_message: raw, get_message_basic_details: { headers: { 'Message-ID' => '<collision@example.com>' }, size: raw.bytesize })
    allow(graph).to receive(:move_message).and_raise(MicrosoftGraph::ApiError.new({ code: 'ErrorAccessDenied', message: 'Denied' }))

    expect { expect { driver.fetch(options, channel) }.to raise_error(MicrosoftGraph::ApiError) }
      .to change { Ticket::Article.where(message_id: '<collision@example.com>').count }.by(1)
    allow(graph).to receive(:move_message).and_return({ id: 'moved' })

    expect { described_class.new.fetch(options, channel.reload) }.not_to change(Ticket::Article, :count)
    expect(Ticket::Article.where(message_id: '<collision@example.com>').reorder(:id).last.body).to include('Distinct body')
  end

  it 'imports changed content instead of skipping a pending message with the same ID' do
    allow(graph).to receive(:move_message).and_raise(MicrosoftGraph::ApiError.new({ code: 'ErrorAccessDenied', message: 'Denied' }))
    expect { driver.fetch(options, channel) }.to raise_error(MicrosoftGraph::ApiError)
    allow(graph).to receive_messages(get_raw_message: 'different body and attachment', move_message: { id: 'moved' })

    driver.fetch(options, channel)

    expect(driver).to have_received(:process).with(channel, 'mail', false)
    expect(driver).to have_received(:process).with(channel, 'different body and attachment', false)
  end

  it 'keeps retry receipts independent when two receiving channels share a Message-ID' do
    second_channel = create(:channel, options: { inbound: { options: options } })
    allow(graph).to receive(:get_message_basic_details).with('message').and_return({ headers: { 'Message-ID' => '<shared@example.com>' }, size: 100 })
    allow(graph).to receive(:move_message).and_raise(MicrosoftGraph::ApiError.new({ code: 'ErrorAccessDenied', message: 'Denied' }))
    expect { driver.fetch(options, channel) }.to raise_error(MicrosoftGraph::ApiError)
    expect { driver.fetch(options, second_channel) }.to raise_error(MicrosoftGraph::ApiError)
    allow(graph).to receive(:move_message).and_return({ id: 'moved' })

    expect(driver.fetch(options, channel.reload)).to include(fetched: 0)
    expect(driver.fetch(options, second_channel.reload)).to include(fetched: 0)
    expect(driver).to have_received(:process).with(channel, 'mail', false).once
    expect(driver).to have_received(:process).with(second_channel, 'mail', false).once
  end

  it 'retries a failed move after a restart even without a Message-ID' do
    allow(graph).to receive(:move_message).and_raise(MicrosoftGraph::ApiError.new({ code: 'ErrorAccessDenied', message: 'Denied' }))
    expect { driver.fetch(options, channel) }.to raise_error(MicrosoftGraph::ApiError)
    restarted_driver = described_class.new
    allow(restarted_driver).to receive(:process)
    allow(graph).to receive(:move_message).and_return({ id: 'moved' })

    expect(restarted_driver.fetch(options, channel.reload)).to include(fetched: 0)
    expect(restarted_driver).not_to have_received(:process)
    expect(channel.reload.preferences[:microsoft_graph_pending_move]).to be_nil
  end

  it 'stores an unparseable message only once when its move is retried' do
    allow(driver).to receive(:process).and_call_original
    allow(driver).to receive(:process_with_timeout).and_raise('unparseable')
    allow(graph).to receive(:move_message).and_raise(MicrosoftGraph::ApiError.new({ code: 'ErrorAccessDenied', message: 'Denied' }))

    expect do
      2.times { expect { driver.fetch(options, channel.reload) }.to raise_error(MicrosoftGraph::ApiError) }
    end.to change(FailedEmail, :count).by(1)
  end

  it 'rolls back processing if its retry receipt cannot be saved' do
    allow(driver).to receive(:process).and_call_original
    allow(driver).to receive(:process_with_timeout).and_raise('unparseable')
    allow(channel).to receive(:update_column).and_raise(ActiveRecord::RecordInvalid)

    expect { expect { driver.fetch(options, channel) }.to raise_error(ActiveRecord::RecordInvalid) }
      .not_to change(FailedEmail, :count)
    expect(graph).not_to have_received(:move_message)
    expect(channel.preferences[:microsoft_graph_pending_move]).to be_nil
  end

  it 'rolls back processing when the receipt update does not persist' do
    allow(driver).to receive(:process).and_call_original
    allow(driver).to receive(:process_with_timeout).and_raise('unparseable')
    allow(channel).to receive(:update_column).and_return(false)

    expect { expect { driver.fetch(options, channel) }.to raise_error(ActiveRecord::RecordNotSaved) }
      .not_to change(FailedEmail, :count)
    expect(graph).not_to have_received(:move_message)
    expect(channel.preferences[:microsoft_graph_pending_move]).to be_nil
  end

  it 'rolls back an article when raw storage fails before recording its move receipt' do
    raw = "From: sender@example.com\r\nTo: mailbox@example.com\r\nSubject: Storage failure\r\nMessage-ID: <storage-failure@example.com>\r\nContent-Type: text/plain; charset=UTF-8\r\n\r\nBody"
    allow(driver).to receive(:process).and_call_original
    allow(graph).to receive(:get_raw_message).and_return(raw)
    allow_any_instance_of(Ticket::Article).to receive(:save_as_raw).and_raise('storage failed')
    article_count = Ticket::Article.count

    expect { driver.fetch(options, channel) }.to change(FailedEmail, :count).by(1)
    expect(Ticket::Article.count).to eq(article_count)
    expect(graph).to have_received(:move_message).with('message', 'destination')
  end

  it 'stores a FailedEmail and receipt after a database error rolls back a partial import' do
    raw = "From: sender@example.com\r\nTo: mailbox@example.com\r\nSubject: Database failure\r\nMessage-ID: <database-failure@example.com>\r\nContent-Type: text/plain; charset=UTF-8\r\n\r\nBody"
    allow(driver).to receive(:process).and_call_original
    allow(graph).to receive(:get_raw_message).and_return(raw)
    allow_any_instance_of(Ticket::Article).to receive(:save_as_raw) { Channel.connection.execute("SELECT 'invalid'::integer") }
    article_count = Ticket::Article.count
    ticket_count = Ticket.count

    expect { driver.fetch(options, channel) }.to change(FailedEmail, :count).by(1)
    expect(Ticket::Article.count).to eq(article_count)
    expect(Ticket.count).to eq(ticket_count)
    expect(graph).to have_received(:move_message).with('message', 'destination')
  end

  it 'retries pending cleanup before an older restored message can overwrite its receipt' do
    allow(graph).to receive(:move_message).with('message', 'destination')
      .and_raise(MicrosoftGraph::ApiError.new({ code: 'ErrorAccessDenied', message: 'Denied' }))
    expect { driver.fetch(options, channel) }.to raise_error(MicrosoftGraph::ApiError)
    allow(graph).to receive_messages(list_messages: { items: [{ id: 'older' }, { id: 'message' }], total_count: 2 }, move_message: { id: 'moved' })

    expect(driver.fetch(options, channel.reload)).to include(fetched: 1)
    expect(driver).to have_received(:process).twice
    expect(graph).to have_received(:move_message).with('message', 'destination').twice
  end

  it 'retries a pending message before a full page of older restored messages' do
    allow(graph).to receive(:move_message).with('message', 'destination')
      .and_raise(MicrosoftGraph::ApiError.new({ code: 'ErrorAccessDenied', message: 'Denied' }))
    expect { driver.fetch(options, channel) }.to raise_error(MicrosoftGraph::ApiError)
    allow(graph).to receive_messages(list_messages: { items: [{ id: 'older' }], total_count: 1001 }, move_message: { id: 'moved' })

    expect(driver.fetch(options, channel.reload)).to include(fetched: 1)
    expect(graph).to have_received(:get_raw_message).with('message').twice
    expect(driver).to have_received(:process).twice
  end

  it 'clears a pending receipt if its remote message has already been removed' do
    allow(graph).to receive(:move_message).with('message', 'destination')
      .and_raise(MicrosoftGraph::ApiError.new({ code: 'ErrorAccessDenied', message: 'Denied' }))
    expect { driver.fetch(options, channel) }.to raise_error(MicrosoftGraph::ApiError)
    allow(graph).to receive_messages(list_messages: { items: [{ id: 'older' }], total_count: 1 }, move_message: { id: 'moved' })
    allow(graph).to receive(:get_message_basic_details).with('message')
      .and_raise(MicrosoftGraph::ApiError.new({ code: 'ErrorItemNotFound', message: 'Gone' }))

    expect(driver.fetch(options, channel.reload)).to include(fetched: 1)
    expect(channel.reload.preferences[:microsoft_graph_pending_move]).to be_nil
    expect(graph).to have_received(:get_message_basic_details).with('message').twice
    expect(driver).to have_received(:process).twice
  end

  %w[delete mark_read].each do |action|
    it "uses its pending receipt after switching to #{action}" do
      allow(graph).to receive(:move_message).with('message', 'destination')
        .and_raise(MicrosoftGraph::ApiError.new({ code: 'ErrorAccessDenied', message: 'Denied' }))
      expect { driver.fetch(options, channel) }.to raise_error(MicrosoftGraph::ApiError)

      expect(driver.fetch(options.merge(post_import_action: action), channel.reload)).to include(fetched: 0)
      expect(driver).to have_received(:process).once
      expect(channel.reload.preferences[:microsoft_graph_pending_move]).to be_nil
      cleanup = action == 'delete' ? :delete_message : :mark_message_as_read
      expect(graph).to have_received(cleanup).with('message')
    end
  end

  it 'does not move fresh verification messages' do
    allow(validator).to receive(:fresh_verify_message?).and_return(true)
    expect(driver.fetch(options, channel)).to include(fetched: 0)
    expect(graph).not_to have_received(:move_message)
  end

  it 'moves oversized messages after storing a rejection' do
    allow(validator).to receive(:too_large?).and_return([20, 10])
    Setting.set('postmaster_send_reject_if_mail_too_large', true)
    outer_transactions = Channel.connection.open_transactions
    allow(driver).to receive(:process_oversized_mail) do
      expect(Channel.connection.open_transactions).to eq(outer_transactions)
    end
    driver.fetch(options, channel)

    expect(driver).to have_received(:process_oversized_mail).with(channel, 'mail')
    expect(graph).to have_received(:move_message)
  end

  it 'retries an oversized message move without sending a second rejection' do
    allow(validator).to receive(:too_large?).and_return([20, 10])
    Setting.set('postmaster_send_reject_if_mail_too_large', true)
    allow(driver).to receive(:process_oversized_mail)
    allow(graph).to receive(:move_message).and_raise(MicrosoftGraph::ApiError.new({ code: 'ErrorAccessDenied', message: 'Denied' }))
    expect { driver.fetch(options, channel) }.to raise_error(MicrosoftGraph::ApiError)
    allow(graph).to receive(:move_message).and_return({ id: 'moved' })

    expect(driver.fetch(options, channel.reload)).to include(fetched: 0)
    expect(driver).to have_received(:process_oversized_mail).once
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
