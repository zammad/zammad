# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Ticket::Article::EmailForwardReply, :aggregate_failures, type: :graphql do
  let(:article)  { create(:ticket_article, :inbound_email, :with_attachment, from: customer.email) }
  let(:agent)    { create(:agent, groups: [article.ticket.group]) }
  let(:customer) { create(:customer) }
  let(:form_id)  { SecureRandom.uuid }

  let(:query) do
    <<~QUERY
      mutation ticketArticleEmailForwardReply($articleId: ID!, $formId: FormId!) {
        ticketArticleEmailForwardReply(articleId: $articleId, formId: $formId) {
          quotableFrom
          quotableTo
          quotableCc
          attachments {
            name
          }
          errors {
            message
            field
          }
        }
      }
    QUERY
  end

  let(:variables) do
    {
      articleId: gql.id(article),
      formId:    form_id
    }
  end

  context 'when logged in as an agent', authenticated_as: :agent do

    context 'when quoting is enabled' do

      let(:expected_response) do
        {
          'quotableFrom' => "#{customer.fullname} <#{customer.email}>",
          'quotableTo'   => article.to,
          'quotableCc'   => nil,
          'attachments'  => [ { 'name' => article.attachments.first.filename } ],
        }
      end

      it 'includes personal data' do
        gql.execute(query, variables: variables)

        expect(gql.result.data).to include(expected_response)
      end
    end

    context 'when quoting is disabled' do

      before do
        Setting.set('ui_ticket_zoom_article_email_full_quote_header', false)
      end

      let(:expected_response) do
        {
          'quotableFrom' => nil,
          'quotableTo'   => nil,
          'quotableCc'   => nil,
          'attachments'  => [ { 'name' => article.attachments.first.filename } ],
        }
      end

      it 'does not include personal data' do
        gql.execute(query, variables: variables)

        expect(gql.result.data).to include(expected_response)
      end
    end

    context 'when no form_id is given' do
      let(:query) do
        <<~QUERY
          mutation ticketArticleEmailForwardReply($articleId: ID!) {
            ticketArticleEmailForwardReply(articleId: $articleId) {
              quotableFrom
              attachments {
                name
              }
            }
          }
        QUERY
      end

      let(:variables) { { articleId: gql.id(article) } }

      it 'skips the attachment cloning and still returns quotable data' do
        gql.execute(query, variables: variables)

        expect(gql.result.data).to include(
          'quotableFrom' => "#{customer.fullname} <#{customer.email}>",
          'attachments'  => [],
        )
      end
    end

    # A blank form_id skips the upload cache authorization - it must not clone
    #   into a cache keyed by the empty string either.
    context 'when the form_id is blank' do
      let(:variables) { { articleId: gql.id(article), formId: '' } }

      it 'skips the attachment cloning like a missing form_id' do
        gql.execute(query, variables: variables)

        expect(gql.result.data).to include('attachments' => [])
      end
    end

    context 'when form_id points to another users cache' do
      let(:other_agent) { create(:agent) }

      before do
        UploadCache.new(form_id).add(
          filename:      'intruder.txt',
          data:          'Intruder content',
          preferences:   { 'Content-Type' => 'text/plain' },
          created_by_id: other_agent.id,
        )
      end

      it 'forbids cloning attachments into another users cache' do
        expect { gql.execute(query, variables: variables) }.not_to change(Store, :count)
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

  end

  context 'when logged in as customer', authenticated_as: :customer do
    before do
      gql.execute(query, variables: variables)
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end

  context 'when not logged in' do
    before do
      gql.execute(query, variables: variables)
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end

  # Without a form_id the upload cache authorization is skipped - the required
  #   ticket.agent permission must still reject even the ticket's own customer,
  #   who would pass the article visibility check.
  context 'when logged in as the ticket customer without a form_id', authenticated_as: :customer do
    let(:article)  { create(:ticket_article, :inbound_email) }
    let(:customer) { article.ticket.customer }

    let(:query) do
      <<~QUERY
        mutation ticketArticleEmailForwardReply($articleId: ID!) {
          ticketArticleEmailForwardReply(articleId: $articleId) {
            quotableFrom
          }
        }
      QUERY
    end

    let(:variables) { { articleId: gql.id(article) } }

    before do
      gql.execute(query, variables: variables)
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end

  describe '#quotableFrom', authenticated_as: :agent do
    let(:expected_response) do
      nil
    end

    let(:email_address) { article.ticket.group.email_address }
    let(:separator)     { Setting.get('ticket_define_email_from_separator') }

    context 'when origin_by is set' do
      before { Setting.set('ticket_define_email_from', 'AgentNameSystemAddressName') }

      let(:user)    { create(:agent) }
      let(:article) { create(:ticket_article, origin_by: user) }

      let(:expected_response) do
        "#{user.fullname} #{separator} #{email_address.name} <#{email_address.email}>"
      end

      it 'works as expected' do
        gql.execute(query, variables: variables)
        expect(gql.result.data[:quotableFrom]).to eq(expected_response)
      end
    end

    context 'when created_by is set' do
      before { Setting.set('ticket_define_email_from', 'AgentNameSystemAddressName') }

      let(:user) { create(:agent) }
      let(:article) { create(:ticket_article, created_by: user) }

      let(:expected_response) do
        "#{user.fullname} #{separator} #{email_address.name} <#{email_address.email}>"
      end

      it 'works as expected' do
        gql.execute(query, variables: variables)
        expect(gql.result.data[:quotableFrom]).to eq(expected_response)
      end
    end

    # The quoted From line follows the configured sender format, like the From
    #   header of the original outbound mail (#5130).
    context 'when the article was created by an agent' do
      let(:user)    { create(:agent) }
      let(:article) { create(:ticket_article, created_by: user) }

      context "when sender format is 'SystemAddressName'" do
        before { Setting.set('ticket_define_email_from', 'SystemAddressName') }

        it 'hides the agent name' do
          gql.execute(query, variables: variables)
          expect(gql.result.data[:quotableFrom]).to eq("#{email_address.name} <#{email_address.email}>")
        end
      end

      context "when sender format is 'AgentName'" do
        before { Setting.set('ticket_define_email_from', 'AgentName') }

        it 'pairs the agent name with the group email address' do
          gql.execute(query, variables: variables)
          expect(gql.result.data[:quotableFrom]).to eq("#{user.fullname} <#{email_address.email}>")
        end
      end

      context 'when the group has no email address' do
        before { article.ticket.group.update!(email_address: nil) }

        it 'falls back to the agent name only' do
          gql.execute(query, variables: variables)
          expect(gql.result.data[:quotableFrom]).to eq(user.fullname)
        end
      end
    end

    context 'when the ticket was moved to another group after the mail was sent' do
      let(:agent)                  { create(:agent, groups: [article.ticket.group, other_group]) }
      let(:user)                   { create(:agent) }
      let(:article)                { create(:ticket_article, created_by: user, sender_name: 'Agent', type_name: 'email') }
      let(:original_email_address) { article.ticket.group.email_address }
      let(:other_group)            { create(:group) }

      before do
        Setting.set('ticket_define_email_from', 'SystemAddressName')
        original_email_address
        article.ticket.update!(group: other_group)
      end

      it 'uses the email address the mail was sent from' do
        gql.execute(query, variables: variables)
        expect(gql.result.data[:quotableFrom]).to eq("#{original_email_address.name} <#{original_email_address.email}>")
      end
    end
  end

  describe '#quotableAuthorName', authenticated_as: :agent do
    let(:query) do
      <<~QUERY
        mutation ticketArticleEmailForwardReply($articleId: ID!) {
          ticketArticleEmailForwardReply(articleId: $articleId) {
            quotableAuthorName
          }
        }
      QUERY
    end

    let(:variables)     { { articleId: gql.id(article) } }
    let(:email_address) { article.ticket.group.email_address }
    let(:user)          { create(:agent) }
    let(:article)       { create(:ticket_article, created_by: user, sender_name: 'Agent', type_name: 'email') }

    context "when sender format is 'SystemAddressName'" do
      before { Setting.set('ticket_define_email_from', 'SystemAddressName') }

      it 'hides the agent name' do
        gql.execute(query, variables: variables)
        expect(gql.result.data[:quotableAuthorName]).to eq(email_address.name)
      end
    end

    context "when sender format is 'AgentName'" do
      before { Setting.set('ticket_define_email_from', 'AgentName') }

      it 'shows the agent name without an address' do
        gql.execute(query, variables: variables)
        expect(gql.result.data[:quotableAuthorName]).to eq("#{user.firstname} #{user.lastname}")
      end
    end

    context 'when the agent has no name' do
      let(:user) { create(:agent, firstname: nil, lastname: nil, email: 'namelessagent@example.com') }

      before { Setting.set('ticket_define_email_from', 'AgentName') }

      it 'falls back to the email address name' do
        gql.execute(query, variables: variables)
        expect(gql.result.data[:quotableAuthorName]).to eq(email_address.name)
      end
    end

    context 'when the mail was sent from a different email address' do
      let(:other_email_address) { create(:email_address) }

      before do
        Setting.set('ticket_define_email_from', 'SystemAddressName')
        article.update!(preferences: article.preferences.merge('email_address_id' => other_email_address.id))
      end

      it 'uses the display name of the recorded address' do
        gql.execute(query, variables: variables)
        expect(gql.result.data[:quotableAuthorName]).to eq(other_email_address.name)
      end
    end

    context 'when the article was created by a customer' do
      let(:user)    { create(:customer) }
      let(:article) { create(:ticket_article, :inbound_email, created_by: user, origin_by: user) }

      before { Setting.set('ticket_define_email_from', 'SystemAddressName') }

      it 'shows the customer name without an address' do
        gql.execute(query, variables: variables)
        expect(gql.result.data[:quotableAuthorName]).to eq("#{user.firstname} #{user.lastname}")
      end
    end

    context 'when the agent has no name and no email address is resolvable' do
      let(:user)    { create(:agent, firstname: nil, lastname: nil, email: 'namelessagent@example.com') }
      let(:article) { create(:ticket_article, :outbound_web, ticket: create(:ticket, group: create(:group, email_address: nil)), created_by: user, origin_by: user) }

      before { Setting.set('ticket_define_email_from', 'AgentName') }

      it 'falls back to a placeholder instead of personal data' do
        gql.execute(query, variables: variables)
        expect(gql.result.data[:quotableAuthorName]).to eq('-')
      end
    end

    context 'when the agent has only a first name' do
      let(:user) { create(:agent, firstname: 'Max', lastname: nil, email: 'maxonly@example.com') }

      before { Setting.set('ticket_define_email_from', 'AgentNameSystemAddressName') }

      it 'combines the single name part without extra whitespace' do
        gql.execute(query, variables: variables)
        expect(gql.result.data[:quotableAuthorName])
          .to eq("Max #{Setting.get('ticket_define_email_from_separator')} #{email_address.name}")
      end
    end

    context 'when the customer has no name' do
      let(:user)    { create(:customer, firstname: nil, lastname: nil, email: 'namelesscustomer@example.com') }
      let(:article) { create(:ticket_article, :inbound_email, created_by: user, origin_by: user) }

      it 'returns no value, leaving the fallback to the client' do
        gql.execute(query, variables: variables)
        expect(gql.result.data[:quotableAuthorName]).to be_nil
      end
    end

    context 'when the article was created by the system user' do
      let(:article) { create(:ticket_article, :system_outbound_email) }

      it 'shows the system user placeholder name like the legacy citation' do
        gql.execute(query, variables: variables)
        expect(gql.result.data[:quotableAuthorName]).to eq('-')
      end
    end
  end

  describe '#quotableTo', authenticated_as: :agent do
    let(:expected_response) do
      nil
    end

    context 'when inbound_email is set' do
      let(:user)    { create(:agent) }
      let(:article) { create(:ticket_article, :inbound_email) }

      let(:expected_response) do
        article.to
      end

      it 'works as expected' do
        gql.execute(query, variables: variables)
        expect(gql.result.data[:quotableTo]).to eq(expected_response)
      end
    end

    context 'when inbound_phone is set' do
      let(:user) { create(:agent) }
      let(:article) { create(:ticket_article, :inbound_phone) }

      let(:expected_response) do
        article.to
      end

      it 'works as expected' do
        gql.execute(query, variables: variables)
        expect(gql.result.data[:quotableTo]).to eq(expected_response)
      end
    end

    context 'when outbound_phone is set' do
      let(:user) { create(:customer) }
      let(:article) { create(:ticket_article, :outbound_phone, ticket: create(:ticket, customer: user)) }

      let(:expected_response) do
        "#{user.fullname} <#{user.email}>"
      end

      it 'works as expected' do
        gql.execute(query, variables: variables)
        expect(gql.result.data[:quotableTo]).to eq(expected_response)
      end
    end

    context 'when the recipient is an agent' do
      # The sender format must not be applied to recipient lines.
      before { Setting.set('ticket_define_email_from', 'SystemAddressName') }

      let(:user)    { create(:agent) }
      let(:article) { create(:ticket_article, :inbound_email, to: "#{user.fullname} <#{user.email}>") }

      let(:expected_response) do
        user.fullname
      end

      it 'does not expose the agent email address' do
        gql.execute(query, variables: variables)
        expect(gql.result.data[:quotableTo]).to eq(expected_response)
      end

      context "when user_name_format is 'last_first'" do
        before { Setting.set('user_name_format', 'last_first') }

        let(:expected_response) do
          "#{user.lastname} #{user.firstname}"
        end

        it 'orders the name parts accordingly' do
          gql.execute(query, variables: variables)
          expect(gql.result.data[:quotableTo]).to eq(expected_response)
        end
      end
    end

    context 'when multiple recipients are present' do
      let(:agent_recipient)    { create(:agent) }
      let(:customer_recipient) { create(:customer) }
      let(:article) do
        create(:ticket_article, :inbound_email,
               to: "#{customer_recipient.fullname} <#{customer_recipient.email}>, unknown@example.org, #{agent_recipient.fullname} <#{agent_recipient.email}>")
      end

      let(:expected_response) do
        "#{customer_recipient.fullname} <#{customer_recipient.email}>, unknown@example.org, #{agent_recipient.fullname}"
      end

      it 'keeps every recipient and hides only the agent email address' do
        gql.execute(query, variables: variables)
        expect(gql.result.data[:quotableTo]).to eq(expected_response)
      end
    end

    context 'when the recipient is an agent without a name' do
      let(:user) { create(:agent, firstname: '', lastname: '', email: 'namelessagent@example.com') }

      # User#fullname falls back to the email address, so this is the To header
      #   Zammad itself generates for such users:
      #   '"user@example.com" <user@example.com>'.
      let(:article) { create(:ticket_article, :inbound_email, to: Channel::EmailBuild.recipient_line(user.fullname, user.email)) }

      let(:expected_response) do
        '-'
      end

      it 'does not fall back to the agent email address' do
        gql.execute(query, variables: variables)
        expect(gql.result.data[:quotableTo]).to eq(expected_response)
      end
    end

    # Pin the raw address extraction for the common header shapes, so future
    #   changes to the pattern fail loudly instead of silently falling back to
    #   the raw header field.
    context 'when the recipient address comes in different header formats' do
      let(:user)    { create(:agent, firstname: 'Edge', lastname: 'Case', email: 'edge.case+tag@mail.example.com') }
      let(:article) { create(:ticket_article, :inbound_email, to: to) }

      context 'with a bare address' do
        let(:to) { user.email }

        it 'resolves the user' do
          gql.execute(query, variables: variables)
          expect(gql.result.data[:quotableTo]).to eq(user.fullname)
        end
      end

      context 'with an unquoted display name' do
        let(:to) { "Edge Case <#{user.email}>" }

        it 'resolves the user' do
          gql.execute(query, variables: variables)
          expect(gql.result.data[:quotableTo]).to eq(user.fullname)
        end
      end

      context 'with a quoted display name' do
        let(:to) { %("Edge Case" <#{user.email}>) }

        it 'resolves the user' do
          gql.execute(query, variables: variables)
          expect(gql.result.data[:quotableTo]).to eq(user.fullname)
        end
      end

      context 'with an unknown recipient' do
        let(:to) { 'Unknown Person <unknown@example.org>' }

        it 'keeps the raw value' do
          gql.execute(query, variables: variables)
          expect(gql.result.data[:quotableTo]).to eq(to)
        end
      end
    end

    context 'when article has no to field set' do
      let(:user)    { create(:customer) }
      let(:article) { create(:ticket_article, :inbound_phone, to: nil) }

      let(:expected_response) do
        nil
      end

      it 'works as expected' do
        gql.execute(query, variables: variables)
        expect(gql.result.data[:quotableTo]).to eq(expected_response)
      end
    end
  end

  describe '#quotableCc', authenticated_as: :agent do
    let(:user) { create(:customer) }
    let(:article) { create(:ticket_article, cc: user.email) }

    let(:expected_response) do
      "#{user.fullname} <#{user.email}>"
    end

    it 'works as expected' do
      gql.execute(query, variables: variables)
      expect(gql.result.data[:quotableCc]).to eq(expected_response)
    end

    context 'when an agent is in Cc' do
      let(:agent_cc) { create(:agent) }
      let(:article)  { create(:ticket_article, cc: "#{user.fullname} <#{user.email}>, #{agent_cc.fullname} <#{agent_cc.email}>") }

      let(:expected_response) do
        "#{user.fullname} <#{user.email}>, #{agent_cc.fullname}"
      end

      it 'hides the agent email address' do
        gql.execute(query, variables: variables)
        expect(gql.result.data[:quotableCc]).to eq(expected_response)
      end
    end
  end
end
