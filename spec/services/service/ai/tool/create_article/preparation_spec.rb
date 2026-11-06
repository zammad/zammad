# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Tool::CreateArticle::Preparation, :aggregate_failures do
  let(:group)  { create(:group) }
  let(:user)   { create(:agent, groups: [group]) }
  let(:ticket) { create(:ticket, group:) }

  def prepare(type, **arguments)
    described_class.execute(ticket: ticket.reload, user:, arguments: { type:, text: 'A message.' }.merge(arguments))
  end

  def channel_ticket(area:, options:, preferences:, type:)
    channel = create(:channel, area:, options:)
    ticket.update!(preferences: preferences.merge(channel_id: channel.id), create_article_type: Ticket::Article::Type.lookup(name: type))
    channel
  end

  %w[note phone web chat fax].each do |type|
    it "records #{type} without claiming direct delivery" do
      prepared = prepare(type)
      expect(prepared).to include(outbound: false, article_data: include(type:, internal: false, content_type: 'text/plain'))
    end
  end

  ['twitter status', 'twitter direct-message', 'facebook feed post', 'facebook direct-message'].each do |type|
    it "refuses unavailable outbound #{type} instead of pretending to send" do
      expect { prepare(type) }.to raise_error(described_class::InvalidArticle, %r{no available outbound delivery})
      expect(ticket.articles).to be_empty
    end
  end

  it 'offers the types Zammad records, a group sends or a channel delivers, and no other' do
    expect(Service::AI::Tool::CreateArticle::ARTICLE_TYPES).to eq(['note', 'phone', 'web', 'chat', 'fax', 'email', 'facebook feed comment', 'sms', 'telegram personal-message', 'whatsapp message'])
    expect(Ticket::Article::Type.pluck(:name)).to include(*Service::AI::Tool::CreateArticle::ARTICLE_TYPES)
  end

  it 'omits an inactive email signature from the message and confirmation' do
    group.update!(email_address: create(:email_address), signature: create(:signature, active: false, body: '<p>Inactive signature</p>'))

    prepared = prepare('email', to: ['customer@example.com'])

    expect(prepared[:article_data][:body]).to eq('A message.')
    expect(prepared[:confirmation][:preview]).to include('A message.')
    expect(prepared[:confirmation][:preview]).not_to include('Inactive signature')
  end

  it 'includes the active email signature by default and allows explicitly omitting it' do
    group.update!(email_address: create(:email_address), signature: create(:signature, body: '<p>Configured signature</p>'))

    expect(prepare('email', to: ['customer@example.com'])[:article_data][:body]).to include('Configured signature')
    expect(prepare('email', to: ['customer@example.com'], include_signature: true)[:article_data][:body]).to include('Configured signature')

    prepared = prepare('email', to: ['customer@example.com'], include_signature: false, text: 'Message with my own signature.')
    expect(prepared[:article_data][:body]).to eq('Message with my own signature.')
    expect(prepared[:confirmation][:preview]).not_to include('Configured signature')
  end

  it 'takes HTML as the REST API does, without the markup Zammad removes, and confirms it as text with the link addresses' do
    group.update!(email_address: create(:email_address), signature: create(:signature, body: '<p>Configured signature</p>'))
    html = '<h2>Summary</h2><p>See <a href="https://example.com/fix">the fix</a>.</p><script>alert(1)</script>'

    note = prepare('note', text: html, content_type: 'text/html')
    expect(note[:article_data]).to include(content_type: 'text/html', body: include('<h2>Summary</h2>'))
    expect(note[:article_data][:body]).not_to include('script')

    email = prepare('email', to: ['customer@example.com'], text: html, content_type: 'text/html')
    expect(email[:article_data]).to include(content_type: 'text/html', body: include('<h2>Summary</h2>', 'Configured signature'))
    expect(email[:confirmation][:preview]).to include('Summary', 'https://example.com/fix')
    expect(email[:confirmation][:preview]).not_to include('<h2>')
  end

  it 'accounts the time the user gave, which the confirmation names' do
    Setting.set('time_accounting', true)

    prepared = prepare('phone', time_unit: 1.5)

    expect(prepared[:article_data]).to include(time_unit: 1.5)
    expect(prepared[:confirmation][:preview]).to include('Time accounted: 1.5')
    expect(prepare('phone', time_unit: 0)[:article_data]).to include(time_unit: 0)
    expect(prepare('phone', time_unit: -1)[:article_data]).to include(time_unit: -1)
  end

  it 'refuses HTML for a channel that sends plain text' do
    channel_ticket(area: 'Sms::Account', options: { adapter: 'sms/twilio', sender: '+49123456789' }, preferences: {}, type: 'sms')
    expect { prepare('sms', to: ['+49111111111'], content_type: 'text/html') }.to raise_error(described_class::InvalidArticle, %r{SMS takes plain text})
  end

  it 'prepares an SMS on the matching ticket without silently truncating' do
    channel_ticket(area: 'Sms::Account', options: { adapter: 'sms/twilio', sender: '+49123456789' }, preferences: {}, type: 'sms')
    prepared = prepare('sms', to: ['+49111111111'])
    expect(prepared).to include(outbound: true, article_data: include(to: '+49111111111', from: '+49123456789'))
    expect { prepare('sms', to: ['+49111111111'], text: 'x' * 161) }.to raise_error(described_class::InvalidArticle, %r{160})
    expect { prepare('sms') }.to raise_error(described_class::InvalidArticle, %r{exactly one})
    expect { prepare('sms', to: ['+49111111111', '+49222222222']) }.to raise_error(described_class::InvalidArticle, %r{exactly one})
  end

  it 'prepares Telegram for the ticket chat and refuses arbitrary destination overrides' do
    channel_ticket(area: 'Telegram::Bot', options: { api_token: 'test-only', bot: { username: 'supportbot' } }, preferences: { telegram: { chat_id: 123 } }, type: 'telegram personal-message')
    expect(prepare('telegram personal-message')).to include(outbound: true, article_data: include(to: '123', from: 'supportbot'))
    expect { prepare('telegram personal-message', to: ['456']) }.to raise_error(described_class::InvalidArticle, %r{omit to})
    expect { prepare('telegram personal-message', text: 'x' * 4097) }.to raise_error(described_class::InvalidArticle, %r{4096})
  end

  it 'prepares WhatsApp inside its 24-hour window and refuses the exact boundary' do
    freeze_time
    channel_ticket(area: 'WhatsApp::Business', options: { adapter: 'whatsapp', phone_number: '49111111111' },
                   preferences: { whatsapp: { timestamp_incoming: 23.hours.ago.to_i.to_s, from: { phone_number: '49222222222' } } }, type: 'whatsapp message')
    expect(prepare('whatsapp message')).to include(outbound: true, article_data: include(to: '49222222222', from: '49111111111'))
    ticket.preferences['whatsapp']['timestamp_incoming'] = 24.hours.ago.to_i.to_s
    ticket.save!
    expect { prepare('whatsapp message') }.to raise_error(described_class::InvalidArticle, %r{24-hour})
  end

  it 'refuses WhatsApp without a valid timestamp or recipient, on closed tickets, and oversized messages' do
    channel_ticket(area: 'WhatsApp::Business', options: { adapter: 'whatsapp' },
                   preferences: { whatsapp: { timestamp_incoming: 'invalid' } }, type: 'whatsapp message')
    expect { prepare('whatsapp message') }.to raise_error(described_class::InvalidArticle, %r{cannot be determined})
    ticket.preferences['whatsapp']['timestamp_incoming'] = Time.current.to_i.to_s
    ticket.save!
    expect { prepare('whatsapp message') }.to raise_error(described_class::InvalidArticle, %r{no WhatsApp recipient})
    ticket.preferences['whatsapp']['from'] = { phone_number: '49222222222' }
    ticket.save!
    expect { prepare('whatsapp message', text: 'x' * 4097) }.to raise_error(described_class::InvalidArticle, %r{4096})
    ticket.update!(state: Ticket::State.lookup(name: 'closed'))
    expect { prepare('whatsapp message') }.to raise_error(described_class::InvalidArticle, %r{closed tickets})
  end

  it 'prepares Facebook comments for an existing post on the configured page' do
    channel_ticket(area: 'Facebook::Account', options: { adapter: 'facebook', pages: [{ id: 'page1', name: 'Support', access_token: 'test-only' }] },
                   preferences: { channel_fb_object_id: 'page1' }, type: 'facebook feed post')
    source = create(:ticket_article, ticket:, type: Ticket::Article::Type.lookup(name: 'facebook feed post'), message_id: 'page1_post1', sender: Ticket::Article::Sender.lookup(name: 'Customer'))
    expect(prepare('facebook feed comment')).to include(outbound: true, article_data: include(to: 'page1_post1', in_reply_to: 'page1_post1', from: 'Support'))
    expect(prepare('facebook feed comment', reply_to_article_id: source.id)).to include(outbound: true, article_data: include(to: 'page1_post1', in_reply_to: 'page1_post1'))
    other = create(:ticket_article, ticket:, type: Ticket::Article::Type.lookup(name: 'note'))
    expect { prepare('facebook feed comment', reply_to_article_id: other.id) }.to raise_error(described_class::InvalidArticle, %r{another channel})
  end

  it 'refuses missing, mismatched and disabled channels before persistence' do
    expect { prepare('whatsapp message') }.to raise_error(described_class::InvalidArticle, %r{matching channel})
    channel = channel_ticket(area: 'Telegram::Bot', options: {}, preferences: {}, type: 'telegram personal-message')
    expect { prepare('whatsapp message') }.to raise_error(described_class::InvalidArticle, %r{matching channel})
    channel.update!(active: false)
    expect { prepare('telegram personal-message') }.to raise_error(described_class::InvalidArticle, %r{matching channel})
    expect(ticket.articles).to be_empty
  end

  it 'refuses type-incompatible headers and destinations rather than ignoring them' do
    expect { prepare('note', to: ['customer@example.com']) }.to raise_error(described_class::InvalidArticle, %r{omit to})
    expect { prepare('phone', cc: ['customer@example.com']) }.to raise_error(described_class::InvalidArticle, %r{Only email})
    [true, false].each do |include_signature|
      expect { prepare('note', include_signature:) }.to raise_error(described_class::InvalidArticle, %r{Only email})
    end
  end
end
