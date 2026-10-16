# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Ticket::Article::QuotedHeader, :aggregate_failures do
  subject(:result) { described_class.with_current_user(agent).execute(article:) }

  let(:agent)    { create(:agent, groups: [article.ticket.group]) }
  let(:customer) { create(:customer) }
  let(:article)  { create(:ticket_article, :inbound_email, from: customer.email) }

  # The expectations spell out first name and last name in this order.
  before { Setting.set('user_name_format', 'first_last') }

  describe '#execute' do
    it 'returns the quoted header lines' do
      expect(result).to have_attributes(
        from: "#{customer.fullname} <#{customer.email}>",
        to:   article.to,
        cc:   nil,
      )
    end

    context 'when the user may not see the article' do
      let(:agent) { create(:agent) }

      it 'fails with Pundit error' do
        expect { result }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context 'when no current user is given' do
      it 'fails' do
        expect { described_class.execute(article:) }.to raise_error(RuntimeError, %r{Current user is required})
      end
    end
  end

  describe '#from' do
    let(:email_address) { article.ticket.group.email_address }
    let(:separator)     { Setting.get('ticket_define_email_from_separator') }

    context 'when origin_by is set' do
      before { Setting.set('ticket_define_email_from', 'AgentNameSystemAddressName') }

      let(:user)    { create(:agent) }
      let(:article) { create(:ticket_article, origin_by: user) }

      it 'follows the sender format' do
        expect(result.from).to eq("#{user.fullname} #{separator} #{email_address.name} <#{email_address.email}>")
      end
    end

    context 'when created_by is set' do
      before { Setting.set('ticket_define_email_from', 'AgentNameSystemAddressName') }

      let(:user)    { create(:agent) }
      let(:article) { create(:ticket_article, created_by: user) }

      it 'follows the sender format' do
        expect(result.from).to eq("#{user.fullname} #{separator} #{email_address.name} <#{email_address.email}>")
      end
    end

    # Inbound mails are created by user 1, the postmaster - its placeholder
    #   identity must not shadow the sender named in the header.
    context 'when an inbound mail was created by the system user' do
      let(:article) { create(:ticket_article, :inbound_email, created_by_id: 1, from: "#{customer.fullname} <#{customer.email}>") }

      it 'resolves the sender through the header' do
        expect(result.from).to eq("#{customer.fullname} <#{customer.email}>")
      end
    end

    context 'when a system mail names no known user in the header' do
      let(:article) { create(:ticket_article, :system_outbound_email) }

      it 'keeps the raw header like the legacy quote header' do
        expect(article.from).to be_present
        expect(result.from).to eq(article.from)
      end
    end

    context 'when an unknown sender is named in the header' do
      let(:article) { create(:ticket_article, :inbound_email, from: 'Unknown Person <unknown@example.org>') }

      it 'keeps the raw header' do
        expect(result.from).to eq('Unknown Person <unknown@example.org>')
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
          expect(result.from).to eq("#{email_address.name} <#{email_address.email}>")
        end
      end

      context "when sender format is 'AgentName'" do
        before { Setting.set('ticket_define_email_from', 'AgentName') }

        it 'pairs the agent name with the group email address' do
          expect(result.from).to eq("#{user.fullname} <#{email_address.email}>")
        end
      end

      context 'when the group has no email address' do
        before { article.ticket.group.update!(email_address: nil) }

        it 'falls back to the agent name only' do
          expect(result.from).to eq(user.fullname)
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
        expect(result.from).to eq("#{original_email_address.name} <#{original_email_address.email}>")
      end
    end
  end

  describe '#author_name' do
    let(:email_address) { article.ticket.group.email_address }
    let(:user)          { create(:agent) }
    let(:article)       { create(:ticket_article, created_by: user, sender_name: 'Agent', type_name: 'email') }

    context "when sender format is 'SystemAddressName'" do
      before { Setting.set('ticket_define_email_from', 'SystemAddressName') }

      it 'hides the agent name' do
        expect(result.author_name).to eq(email_address.name)
      end
    end

    context "when sender format is 'AgentName'" do
      before { Setting.set('ticket_define_email_from', 'AgentName') }

      it 'shows the agent name without an address' do
        expect(result.author_name).to eq("#{user.firstname} #{user.lastname}")
      end
    end

    context 'when the agent has no name' do
      let(:user) { create(:agent, firstname: nil, lastname: nil, email: 'namelessagent@example.com') }

      before { Setting.set('ticket_define_email_from', 'AgentName') }

      it 'falls back to the email address name' do
        expect(result.author_name).to eq(email_address.name)
      end
    end

    context 'when the mail was sent from a different email address' do
      let(:other_email_address) { create(:email_address) }

      before do
        Setting.set('ticket_define_email_from', 'SystemAddressName')
        article.update!(preferences: article.preferences.merge('email_address_id' => other_email_address.id))
      end

      it 'uses the display name of the recorded address' do
        expect(result.author_name).to eq(other_email_address.name)
      end
    end

    context 'when the article was created by a customer' do
      let(:user)    { create(:customer) }
      let(:article) { create(:ticket_article, :inbound_email, created_by: user, origin_by: user) }

      before { Setting.set('ticket_define_email_from', 'SystemAddressName') }

      it 'shows the customer name without an address' do
        expect(result.author_name).to eq("#{user.firstname} #{user.lastname}")
      end

      context "when user_name_format is 'last_first_comma'" do
        before { Setting.set('user_name_format', 'last_first_comma') }

        it 'orders the name parts accordingly' do
          expect(result.author_name).to eq("#{user.lastname}, #{user.firstname}")
        end
      end
    end

    context 'when the agent has no name and no email address is resolvable' do
      let(:user) { create(:agent, firstname: nil, lastname: nil, email: 'namelessagent@example.com') }

      # Create as the agent - otherwise the fill-up hook makes user 1 the author
      #   when this example runs first in the process.
      let(:article) do
        UserInfo.with_user_id(user.id) do
          create(:ticket_article, :outbound_web, ticket: create(:ticket, group: create(:group, email_address: nil)), created_by: user, origin_by: user)
        end
      end

      before { Setting.set('ticket_define_email_from', 'AgentName') }

      it 'falls back to the agent label instead of personal data' do
        expect(result.author_name).to eq('Agent')
      end
    end

    context 'when the agent has only a first name' do
      let(:user) { create(:agent, firstname: 'Max', lastname: nil, email: 'maxonly@example.com') }

      before { Setting.set('ticket_define_email_from', 'AgentNameSystemAddressName') }

      it 'combines the single name part without extra whitespace' do
        expect(result.author_name).to eq("Max #{Setting.get('ticket_define_email_from_separator')} #{email_address.name}")
      end
    end

    context 'when the customer has no name' do
      let(:user)    { create(:customer, firstname: nil, lastname: nil, email: 'namelesscustomer@example.com') }
      let(:article) { create(:ticket_article, :inbound_email, created_by: user, origin_by: user) }

      it 'returns no value, leaving the fallback to the client' do
        expect(result.author_name).to be_nil
      end
    end

    context 'when the article was created by the system user' do
      let(:article) { create(:ticket_article, :system_outbound_email) }

      it 'shows the system user placeholder name like the legacy citation' do
        expect(result.author_name).to eq('-')
      end
    end
  end

  describe '#to' do
    context 'when inbound_email is set' do
      let(:article) { create(:ticket_article, :inbound_email) }

      it 'keeps the raw recipient' do
        expect(result.to).to eq(article.to)
      end
    end

    context 'when inbound_phone is set' do
      let(:phone_group)   { create(:group) }
      let(:email_address) { phone_group.email_address }
      let(:article)       { create(:ticket_article, :inbound_phone, to: to) }

      context 'when the recipient is the group name' do
        let(:to) { phone_group.name }

        it 'quotes the group email address' do
          expect(result.to).to eq("#{email_address.name} <#{email_address.email}>")
        end

        # Like every other address in the quoted header, the group address goes
        #   through the mailbox formatter.
        context 'when the address display name contains a comma' do
          before { email_address.update!(name: 'Support, Sales') }

          it 'quotes the display name' do
            expect(result.to).to eq(%("Support, Sales" <#{email_address.email}>))
          end
        end
      end

      context 'when the recipient is an unknown group name' do
        let(:to) { 'Unknown Group' }

        it 'keeps the raw value' do
          expect(result.to).to eq(to)
        end
      end

      context 'when the group has no email address' do
        let(:to) { create(:group, email_address: nil).name }

        it 'keeps the raw value' do
          expect(result.to).to eq(to)
        end
      end
    end

    context 'when outbound_phone is set' do
      let(:user)    { create(:customer) }
      let(:article) { create(:ticket_article, :outbound_phone, ticket: create(:ticket, customer: user)) }

      it 'renders the customer with the address' do
        expect(result.to).to eq("#{user.fullname} <#{user.email}>")
      end
    end

    context 'when the recipient is an agent' do
      # The sender format must not be applied to recipient lines.
      before { Setting.set('ticket_define_email_from', 'SystemAddressName') }

      let(:user)    { create(:agent) }
      let(:article) { create(:ticket_article, :inbound_email, to: "#{user.fullname} <#{user.email}>") }

      it 'does not expose the agent email address' do
        expect(result.to).to eq(user.fullname)
      end

      context "when user_name_format is 'last_first'" do
        before { Setting.set('user_name_format', 'last_first') }

        it 'orders the name parts accordingly' do
          expect(result.to).to eq("#{user.lastname} #{user.firstname}")
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

      it 'keeps every recipient and hides only the agent email address' do
        expect(result.to).to eq("#{customer_recipient.fullname} <#{customer_recipient.email}>, unknown@example.org, #{agent_recipient.fullname}")
      end
    end

    context 'when the recipient is an agent without a name' do
      let(:user) { create(:agent, firstname: '', lastname: '', email: 'namelessagent@example.com') }

      # User#fullname falls back to the email address, so this is the To header
      #   Zammad itself generates for such users:
      #   '"user@example.com" <user@example.com>'.
      let(:article) { create(:ticket_article, :inbound_email, to: Channel::EmailBuild.recipient_line(user.fullname, user.email)) }

      it 'does not fall back to the agent email address' do
        expect(result.to).to eq('Agent')
      end

      context 'when the current agent uses another locale' do
        let(:agent) { create(:agent, groups: [article.ticket.group], preferences: { locale: 'es-es' }) }

        # The test database only carries the German catalog, and 'Agent' is
        #   the same word there.
        before { create(:translation, locale: 'es-es', source: 'Agent', target: 'Agente') }

        it 'translates the label' do
          expect(result.to).to eq('Agente')
        end
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
          expect(result.to).to eq(user.fullname)
        end
      end

      context 'with an unquoted display name' do
        let(:to) { "Edge Case <#{user.email}>" }

        it 'resolves the user' do
          expect(result.to).to eq(user.fullname)
        end
      end

      context 'with a quoted display name' do
        let(:to) { %("Edge Case" <#{user.email}>) }

        it 'resolves the user' do
          expect(result.to).to eq(user.fullname)
        end
      end

      context 'with an unknown recipient' do
        let(:to) { 'Unknown Person <unknown@example.org>' }

        it 'keeps the raw value' do
          expect(result.to).to eq(to)
        end
      end

      context 'with an address in upper case' do
        let(:to) { "Edge Case <#{user.email.upcase}>" }

        it 'resolves the user' do
          expect(result.to).to eq(user.fullname)
        end
      end
    end

    # Comma splitting would tear a quoted display name apart and leave a stray
    #   name fragment next to the scrubbed recipient.
    context 'when a quoted display name contains a comma' do
      let(:agent_recipient)    { create(:agent, firstname: 'John', lastname: 'Doe') }
      let(:customer_recipient) { create(:customer, firstname: 'Jane', lastname: 'Roe') }
      let(:article)            { create(:ticket_article, :inbound_email, to: to) }

      context 'when the recipient is an agent' do
        let(:to) { %("Doe, John" <#{agent_recipient.email}>, other@example.org) }

        it 'renders the agent name only, without fragments' do
          expect(result.to).to eq('John Doe, other@example.org')
        end
      end

      context 'when the recipient is a customer' do
        let(:to) { %("Roe, Jane" <#{customer_recipient.email}>, other@example.org) }

        it 'renders the customer with the address' do
          expect(result.to).to eq("#{customer_recipient.fullname} <#{customer_recipient.email}>, other@example.org")
        end
      end

      context 'when the recipient is unknown' do
        let(:to) { %("Doe, Unknown" <unknown@example.org>, other@example.org) }

        it 'keeps the mailbox intact' do
          expect(result.to).to eq(to)
        end
      end

      context 'when the header cannot be parsed as a mailbox list' do
        let(:to) { "invalid sender, realname <#{agent_recipient.email}>" }

        it 'falls back to comma splitting and still scrubs the agent' do
          expect(result.to).to eq('invalid sender, John Doe')
        end
      end

      context 'when the header is an empty group without mailboxes' do
        let(:to) { 'undisclosed-recipients:;' }

        it 'keeps the raw value' do
          expect(result.to).to eq(to)
        end
      end
    end

    context 'when the recipient line has an unusual shape' do
      let(:agent_recipient) { create(:agent, firstname: 'John', lastname: 'Doe') }
      let(:article)         { create(:ticket_article, :inbound_email, to: to) }

      before { agent_recipient }

      context 'with whitespace only' do
        let(:to) { '   ' }

        it 'returns no value' do
          expect(result.to).to be_nil
        end
      end

      context 'with a name only' do
        let(:to) { 'Nicole Braun' }

        it 'keeps the raw value' do
          expect(result.to).to eq(to)
        end
      end

      context 'with a name containing a comma only' do
        let(:to) { 'Braun, Nicole' }

        it 'keeps the raw value' do
          expect(result.to).to eq(to)
        end
      end

      context 'with a name and an address without angle brackets' do
        let(:to) { "John Doe #{agent_recipient.email}" }

        it 'still resolves the agent' do
          expect(result.to).to eq('John Doe')
        end
      end

      context 'with a trailing separator' do
        let(:to) { "#{agent_recipient.email}," }

        it 'renders no empty recipient' do
          expect(result.to).to eq('John Doe')
        end
      end

      context 'with semicolon separated recipients' do
        let(:to) { "#{agent_recipient.email}; other@example.org" }

        it 'scrubs every recipient' do
          expect(result.to).to eq('John Doe, other@example.org')
        end
      end

      context 'with a named group of recipients' do
        let(:to) { "Team: #{agent_recipient.email}, other@example.org;" }

        it 'renders the group members' do
          expect(result.to).to eq('John Doe, other@example.org')
        end
      end

      context 'with a non-ASCII display name of an unknown recipient' do
        let(:to) { 'Jörg Müller <unknown@example.org>' }

        it 'keeps the mailbox, quoting the display name' do
          expect(result.to).to eq('"Jörg Müller" <unknown@example.org>')
        end
      end

      context 'with a non-ASCII display name of an agent' do
        let(:to) { "Jörg Müller <#{agent_recipient.email}>" }

        it 'renders the agent name only' do
          expect(result.to).to eq('John Doe')
        end
      end
    end

    context 'when article has no to field set' do
      let(:article) { create(:ticket_article, :inbound_phone, to: nil) }

      it 'returns no value' do
        expect(result.to).to be_nil
      end
    end
  end

  describe '#cc' do
    let(:user)    { create(:customer) }
    let(:article) { create(:ticket_article, cc: user.email) }

    it 'renders the customer with the address' do
      expect(result.cc).to eq("#{user.fullname} <#{user.email}>")
    end

    context 'when an agent is in Cc' do
      let(:agent_cc) { create(:agent) }
      let(:article)  { create(:ticket_article, cc: "#{user.fullname} <#{user.email}>, #{agent_cc.fullname} <#{agent_cc.email}>") }

      it 'hides the agent email address' do
        expect(result.cc).to eq("#{user.fullname} <#{user.email}>, #{agent_cc.fullname}")
      end
    end
  end
end
