# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Tool::CreateArticle, :aggregate_failures, performs_jobs: true do
  # rubocop:disable-next Lint/InterpolationCheck
  let(:group)     { create(:group, email_address: create(:email_address), signature: create(:signature, body: '<p>Kind regards, #{user.firstname}</p>')) }
  let(:agent)     { create(:agent, groups: [group]) }
  let(:token)     { create(:token, user: agent, preferences: { permission: ['ticket.agent'] }) }
  let(:ticket)    { create(:ticket, group:) }
  let(:arguments) { { ticket_id: ticket.id, type: 'email', text: 'The fix ships tomorrow.', to: ['customer@example.com'] } }

  before do
    allow_any_instance_of(Channel::Driver::BaseEmailOutbound).to receive(:deliver_mail).and_raise('Live delivery is forbidden')
  end

  def call(arguments = self.arguments, context: nil, token: self.token)
    Service::MCPServer::CallTool.execute(tool: described_class, arguments:, user: agent, token:, server_context: context).to_h
  end

  it 'queues an email as the token user, with the configured sender and rendered signature' do
    expect { call }.to have_enqueued_job(TicketArticleCommunicateEmailJob)
    article = ticket.articles.last
    expect(article).to have_attributes(type: Ticket::Article::Type.lookup(name: 'email'), sender: Ticket::Article::Sender.lookup(name: 'Agent'), internal: false, created_by: agent)
    expect(article.from).to include(group.email_address.email)
    expect(article.body).to include('The fix ships tomorrow.', "Kind regards, #{agent.firstname}")
    expect(article.subject).to eq(ticket.subject_clean(ticket.title))
    expect(article.to).to eq('customer@example.com')
    expect(article.cc).to eq('')
  end

  it 'returns a compact saved or queued receipt valid against its output schema' do
    result = call
    expect(result[:structuredContent]).to include('outcome' => 'queued', 'article_id' => ticket.articles.last.id, 'to' => 'customer@example.com', 'internal' => false)
    expect(output_schema_errors(described_class.tool_output_schema, result[:structuredContent])).to be_empty
    expect(result[:content].first[:text]).to include('queued', ticket.number)
    result = call({ ticket_id: ticket.id, type: 'phone', text: 'Spoke to the customer.' })
    expect(result[:structuredContent]).to include('outcome' => 'saved', 'type' => 'phone')
  end

  it 'normalizes and deduplicates explicit email recipients and CC' do
    result = call(arguments.merge(to: ['CUSTOMER@example.com', 'Customer <customer@example.com>'], cc: ['customer@example.com', 'Alex <alex@example.com>']))
    expect(result[:structuredContent]).to include('to' => 'customer@example.com', 'cc' => 'alex@example.com')
  end

  it 'treats plain text as text, not HTML or an inline attachment' do
    call(arguments.merge(text: '<img src="data:image/png;base64,abcd">'))
    expect(ticket.articles.last.body).to include('&lt;img')
    expect(ticket.articles.last.attachments).to be_empty
  end

  it 'preserves configured signature images through the article service' do
    image = 'iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg=='
    UserInfo.with_user_id(agent.id) do
      group.signature.update!(body: "<p>Support</p><img src=\"data:image/png;base64,#{image}\">")
    end
    call
    article = ticket.articles.last
    expect(article.attachments).to be_one
    expect(article.body).to include('cid:')
  end

  it 'delivers the prepared email into the test mailer with its effective headers and signature' do
    allow_any_instance_of(Channel::Driver::BaseEmailOutbound).to receive(:deliver_mail).and_call_original
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('ZAMMAD_MAIL_TO_FILE').and_return(nil)
    allow(ENV).to receive(:[]).with('ZAMMAD_MAIL_PRETEND_NOT_TEST').and_return('0')
    group.email_address.channel.update!(options: { outbound: { adapter: 'sendmail' } })
    call(arguments.merge(cc: ['alex@example.com']))
    article = ticket.articles.last

    expect { TicketArticleCommunicateEmailJob.perform_now(article.id) }.to change { ActionMailer::Base.deliveries.size }.by(1)
    mail = ActionMailer::Base.deliveries.last
    expect(mail.delivery_method).to be_a(Mail::TestMailer)
    expect(mail.to).to eq(['customer@example.com'])
    expect(mail.cc).to eq(['alex@example.com'])
    expect(mail.from).to eq([group.email_address.email])
    expect(mail.subject).to eq(ticket.subject_build(article.subject, 'reply'))
    expect(mail.html_part.decoded).to include('The fix ships tomorrow.', "Kind regards, #{agent.firstname}")
  end

  it 'requires explicit email recipients rather than falling back to the customer or CC' do
    [arguments.except(:to), arguments.merge(to: [], cc: ['alex@example.com'])].each do |input|
      expect(call(input)).to include(isError: true, content: [include(text: include('explicit to'))])
    end
    expect(ticket.articles).to be_empty
  end

  it 'rejects invalid recipients, blank messages and arbitrary write attributes without queuing anything' do
    [arguments.merge(to: ['bad']), arguments.merge(cc: ["alex@example.com\nBcc: other@example.com"]),
     arguments.merge(text: ' '), arguments.merge(attachments: []), arguments.merge(from: 'someone@example.com'),
     arguments.merge(preferences: { channel_id: 42 }), arguments.merge(confirmed: true)].each do |input|
      expect(call(input)).to include(isError: true)
    end
    expect(ticket.articles).to be_empty
    expect(TicketArticleCommunicateEmailJob).not_to have_been_enqueued
  end

  it 'requires a boolean for the signature option' do
    ['false', nil, 0].each do |include_signature|
      expect(call(arguments.merge(include_signature:))).to include(isError: true, content: [include(text: include('must be of type boolean'))])
    end
    expect(ticket.articles).to be_empty
    expect(TicketArticleCommunicateEmailJob).not_to have_been_enqueued
  end

  it 'threads only to an article on the named ticket' do
    source = create(:ticket_article, ticket:, message_id: '<original@example.com>')
    call(arguments.merge(reply_to_article_id: source.id))
    expect(ticket.articles.last.in_reply_to).to eq(source.message_id)
    foreign = create(:ticket_article)
    expect { call(arguments.merge(reply_to_article_id: foreign.id)) }.not_to change(Ticket::Article, :count)
  end

  it 'refuses missing or disabled sender configuration before persistence' do
    group.update!(email_address: nil)
    expect(call).to include(isError: true, content: [include(text: include('email sender'))])
    expect(ticket.articles).to be_empty
  end

  it 'keeps the existing internal note boundary and annotations unchanged' do
    result = Service::MCPServer::CallTool.execute(tool: Service::AI::Tool::AddInternalNote, arguments: { ticket_id: ticket.id, text: 'Email this!', type: 'email' }, user: agent, token:).to_h
    expect(result[:isError]).to be(true)
    expect(ticket.articles).to be_empty
    expect(Service::MCPServer::ToolDefinition.execute(tool: Service::AI::Tool::AddInternalNote, user: agent, token:).to_h[:annotations]).to include(destructiveHint: false, openWorldHint: false)
    expect(Service::MCPServer::ToolDefinition.execute(tool: described_class, user: agent, token:).to_h[:annotations]).to eq(readOnlyHint: false, destructiveHint: true, idempotentHint: false, openWorldHint: true)
  end

  it 'does not offer the write to the harness or to a token without agent permission' do
    expect(Service::AI::Tool::Runtime::Router.offered_tools(surface: :harness, user: agent, audience: AI::Harness::Audience::HUMAN_AGENTS)).not_to include(described_class)
    restricted = create(:token, user: agent, preferences: { permission: ['user_preferences.calendar'] })
    expect(call(token: restricted)).to include(isError: true, content: [include(text: include('unknown_tool'))])
    expect(ticket.articles).to be_empty
  end

  it 'refuses read-only access as such, and customer-only access like a missing ticket' do
    agent.group_ids_access_map = { group.id => 'read' }
    expect(call[:content].first[:text]).to include('read_only')
    agent.group_ids_access_map = {}
    agent.roles << Role.find_by(name: 'Customer')
    ticket.update!(customer: agent)
    expect(call[:content]).to eq(call(arguments.merge(ticket_id: 0))[:content])
    expect(ticket.articles).to be_empty
  end

  it 'asks once for the time where time accounting asks for it, and writes the article once the user skips it' do
    Setting.set('time_accounting', true)
    Setting.set('time_accounting_selector', { condition: {} })
    expect(call).to include(isError: true, content: [include(text: include('asks for the time spent', 'skip_time_accounting: true'))])
    expect(ticket.articles).to be_empty

    call(arguments.merge(skip_time_accounting: true))
    expect(ticket.articles.sole.ticket_time_accounting).to be_nil
  end

  context 'with channel delivery' do
    {
      'sms'                       => ['Sms::Account', { adapter: 'sms/twilio', sender: '+49111111111' }, {}, CommunicateSmsJob],
      'telegram personal-message' => ['Telegram::Bot', { api_token: 'test-only', bot: { username: 'support' } }, { telegram: { chat_id: 123 } }, CommunicateTelegramJob],
      'whatsapp message'          => ['WhatsApp::Business', { adapter: 'whatsapp', name: 'Support', phone_number: '49111111111' }, { whatsapp: { from: { phone_number: '49222222222', display_name: 'Customer' } } }, CommunicateWhatsappJob],
    }.each do |type, (area, options, preferences, job)|
      it "queues #{type} through the existing delivery job as the token user" do
        channel = create(:channel, area:, options:)
        settings = preferences.deep_dup
        settings[:whatsapp][:timestamp_incoming] = Time.current.to_i.to_s if type == 'whatsapp message'
        ticket.update!(preferences: settings.merge(channel_id: channel.id), create_article_type: Ticket::Article::Type.lookup(name: type))
        input = { ticket_id: ticket.id, type:, text: 'A channel reply.' }
        input[:to] = ['+49222222222'] if type == 'sms'

        expect { call(input) }.to have_enqueued_job(job)
        expect(ticket.articles.last).to have_attributes(created_by: agent, internal: false, body: 'A channel reply.')
      end
    end
  end
end
