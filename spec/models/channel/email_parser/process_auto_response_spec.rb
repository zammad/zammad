# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Channel::EmailParser process with auto-response', performs_jobs: true, type: :model do

  describe 'auto-response and agent notification triggers', :aggregate_failures do
    let(:agent1) { create(:agent, groups: Group.all) }

    before do
      Trigger.destroy_all # Default DB state includes three sample triggers
      create(:email_address) # gets auto-assigned to the sole existing group
      agent1
    end

    def create_auto_reply_trigger(name, state: 'new')
      Trigger.create!(
        name:                 name,
        condition:            {
          'ticket.action'   => {
            'operator' => 'is',
            'value'    => 'create',
          },
          'ticket.state_id' => {
            'operator' => 'is',
            'value'    => Ticket::State.lookup(name: state).id.to_s,
          }
        },
        perform:              {
          'notification.email' => {
            # rubocop:disable Lint/InterpolationCheck
            'body'      => 'some text<br>#{ticket.customer.lastname}<br>#{ticket.title}',
            'recipient' => 'ticket_customer',
            'subject'   => 'Thanks for your inquiry (#{ticket.title})!',
            # rubocop:enable Lint/InterpolationCheck
          },
          'ticket.priority_id' => {
            'value' => Ticket::Priority.lookup(name: '3 high').id.to_s,
          },
          'ticket.tags'        => {
            'operator' => 'add',
            'value'    => 'aa, kk, auto-reply',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )
    end

    def create_agent_notification_trigger(name, set_state: nil)
      perform = {
        'notification.email' => {
          # rubocop:disable Lint/InterpolationCheck
          'body'      => 'some text<br>#{ticket.customer.lastname}<br>#{ticket.title}',
          'recipient' => 'ticket_agents',
          'subject'   => 'New Ticket add. info (#{ticket.title})!',
          # rubocop:enable Lint/InterpolationCheck
        },
        'ticket.priority_id' => {
          'value' => Ticket::Priority.lookup(name: '3 high').id.to_s,
        },
        'ticket.tags'        => {
          'operator' => 'add',
          'value'    => 'aa, kk, agent-notification',
        },
      }
      perform['ticket.state_id'] = { 'value' => Ticket::State.lookup(name: set_state).id.to_s } if set_state

      Trigger.create!(
        name:                 name,
        condition:            {
          'ticket.state_id' => {
            'operator' => 'is',
            'value'    => Ticket::State.lookup(name: 'new').id.to_s,
          }
        },
        perform:              perform,
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )
    end

    def process_mail(*headers)
      raw = ['From: me@example.com', 'To: customer@example.com', 'Subject: some new subject', *headers].join("\n")
      process_raw_mail("#{raw}\n\nSome Text")
    end

    def process_raw_mail(raw)
      ticket, _article, _user, mail = Channel::EmailParser.new.process({}, raw)
      perform_enqueued_jobs

      [ticket.reload, mail]
    end

    def article_matcher(kind)
      case kind
      when :customer
        have_attributes(from: 'me@example.com', to: 'customer@example.com', sender: have_attributes(name: 'Customer'), type: have_attributes(name: 'email'))
      when :notification
        have_attributes(subject: include('New Ticket add. info'), to: include(agent1.email).and(satisfy { |to| to.exclude?('me@example.com') }), sender: have_attributes(name: 'System'), type: have_attributes(name: 'email'))
      when :auto_reply
        have_attributes(subject: include('Thanks for your inquiry'), to: include('me@example.com'), sender: have_attributes(name: 'System'), type: have_attributes(name: 'email'))
      end
    end

    def expect_ticket(ticket, state:, tags:, articles:)
      expect(ticket).to have_attributes(state: have_attributes(name: state), priority: have_attributes(name: '3 high'))
      expect(ticket.tag_list).to match_array(tags)
      expect(ticket.articles.to_a).to match(articles.map { |kind| article_matcher(kind) })
    end

    describe 'auto-response headers' do
      before { create_auto_reply_trigger('002 auto reply') }

      {
        []                                 => true,
        ['X-Loop: yes']                    => false,
        ['Precedence: Bulk']               => false,
        ['Auto-Submitted: auto-generated'] => false,
        ['X-Auto-Response-Suppress: All']  => false,
      }.each do |headers, auto_response|
        it "#{auto_response ? 'sends' : 'does not send'} an auto reply with headers #{headers.inspect}" do
          ticket, mail = process_mail(*headers)

          expect(mail[:'x-zammad-send-auto-response']).to be(auto_response)
          expect(ticket.articles.count).to eq(auto_response ? 2 : 1)
        end
      end

      let(:vacation_response) do
        "Return-Path: <XX@XX.XX>
X-Original-To: sales@zammad.com
Received: from mail-qk0-f170.example.com (mail-qk0-f170.example.com [209.1.1.1])
    by mail.zammad.com (Postfix) with ESMTPS id C3AED5FE2E
    for <sales@zammad.com>; Mon, 22 Aug 2016 19:03:15 +0200 (CEST)
Received: by mail-qk0-f170.example.com with SMTP id t7so87721720qkh.1
        for <sales@zammad.com>; Mon, 22 Aug 2016 10:03:15 -0700 (PDT)
DKIM-Signature: v=1; a=rsa-sha256; c=relaxed/relaxed;
        d=XX.XX; s=example;
        h=to:from:date:message-id:subject:mime-version:precedence
         :auto-submitted:content-transfer-encoding:content-disposition;
        bh=SL5tTVvGdxsKjLic38irxzlP439P3jixJH0QTG1HJ5I=;
        b=CIk3PLELgjOCagyiFFbd6rlb8ZRDGYRUrg5Dntxa7e5X+PT4cgL+IE13N9TFkK8ZUJ
         GohlaPLGiBymIYLTtYMKUpcf22oiX8ZgGiSu1aEMC1Gsa1ZDf+vpy4kd4+7EecRT3IWF
         4RafQxeaqe67budhQpO1Z6UAel6BdJj0xguKM=
X-Google-DKIM-Signature: v=1; a=rsa-sha256; c=relaxed/relaxed;
        d=1e100.net; s=20130820;
        h=x-gm-message-state:to:from:date:message-id:subject:mime-version
         :precedence:auto-submitted:content-transfer-encoding
         :content-disposition;
        bh=SL5tTVvGdxsKjLic38irxzlP439P3jixJH0QTG1HJ5I=;
        b=PYULo3xigc4O/cuNZ79OathQ5HDMFWWIwUxz6CHbpXDQR5k3EPy/skJU1992hVz9Rl
         xiGwScBCkMqOjlxHjQSWhFJIxNtdvMk4m0bixBZ79IEvRuQa9cEbqjf6efnV58br5ftQ
         2osHrtQczoSqLE/d61/o102RfQ0avVyX8XNJik0iepg8MiCY7LTOE9hrbnuDDLxgQecH
         rMEfkR7bafcUj1YEto5Vd7uV11cVZYx8UIQqVAVbfygv8dTSFeOzz3NyM0M41rRexfYH
         79Yi5i7z/Wk6q2427wkJ3FIR1B7VQVQEmcq/Texbch+gAXPGBNPUHdg2WHt7NXGktrHL
         d3DA==
X-Gm-Message-State: AE9vXwMCTnihGiG/tc7xNNlhFLcEK6DPp7otypJg5e4alD3xGK2R707BP29druIi/mcdNyaHg1vP5lSZ8EvrwvOF8iA0HNFhECGjBTJ40YrSJAR8E89xVwxFv/er+U3vEpqmPmt+hL4QhxK/+D2gKOcHSxku
X-Received: by 10.1.1.1 with SMTP id 17mr25015996qkf.279.1471885393931;
        Mon, 22 Aug 2016 10:03:13 -0700 (PDT)
To: sales@zammad.com
From: \"XXX\" <XX@XX.XX>
Date: Mon, 22 Aug 2016 10:03:13 -0700
Message-ID: <CA+kqV8PH1DU+zcSx3M00Hrm_oJedRLjbgAUdoi9p0+sMwYsyUg@mail.gmail.com>
Subject: XX PieroXXway - vacation response RE: Callback Request: XX XX [Ticket#1118974]
MIME-Version: 1.0
Precedence: bulk
X-Autoreply: yes
Auto-Submitted: auto-replied
Content-Type: text/html; charset=UTF-8
Content-Transfer-Encoding: quoted-printable
Content-Disposition: inline

test"
      end

      it 'does not send an auto reply to a mail with a message id of the own system' do
        ticket, mail = process_mail("Message-ID: <1234@#{Setting.get('fqdn')}>")

        expect(mail[:'x-zammad-send-auto-response']).to be(false)
        expect(ticket.articles.count).to eq(1)
      end

      it 'sends an auto reply to a mail with a message id of another system' do
        ticket, mail = process_mail("Message-ID: <1234@not_matching.#{Setting.get('fqdn')}>")

        expect(mail[:'x-zammad-send-auto-response']).to be(true)
        expect(ticket.articles.count).to eq(2)
      end

      it 'does not send an auto reply to a vacation response' do
        ticket, mail = process_raw_mail(vacation_response)

        expect(mail[:'x-zammad-send-auto-response']).to be(false)
        expect(ticket.articles.count).to eq(1)
      end
    end

    shared_examples 'running the agent notification only for a mail with auto-response headers' do |state:|
      it 'runs the agent notification but not the auto reply for a mail with auto-response headers' do
        ticket, mail = process_mail('X-Loop: yes')

        expect(mail[:'x-zammad-send-auto-response']).to be(false)
        expect_ticket(ticket, state: state, tags: %w[aa kk agent-notification], articles: %i[customer notification])
      end
    end

    context 'when the agent notification trigger comes first (auto reply check - 1)' do
      before do
        create_auto_reply_trigger('002 auto reply')
        create_agent_notification_trigger('001 additional agent notification')
      end

      [false, true].each do |recursive|
        context "with ticket_trigger_recursive #{recursive}" do
          before { Setting.set('ticket_trigger_recursive', recursive) }

          include_examples 'running the agent notification only for a mail with auto-response headers', state: 'new'

          it 'sends the agent notification first, then the auto reply' do
            ticket, mail = process_mail

            expect(mail[:'x-zammad-send-auto-response']).to be(true)
            expect_ticket(ticket, state: 'new', tags: %w[aa kk agent-notification auto-reply], articles: %i[customer notification auto_reply])
          end
        end
      end
    end

    context 'when the auto reply trigger comes first (auto reply check - 2)' do
      before do
        create_auto_reply_trigger('001 auto reply')
        create_agent_notification_trigger('002 additional agent notification')
      end

      [false, true].each do |recursive|
        context "with ticket_trigger_recursive #{recursive}" do
          before { Setting.set('ticket_trigger_recursive', recursive) }

          include_examples 'running the agent notification only for a mail with auto-response headers', state: 'new'

          it 'sends the auto reply first, then the agent notification' do
            ticket, mail = process_mail

            expect(mail[:'x-zammad-send-auto-response']).to be(true)
            expect_ticket(ticket, state: 'new', tags: %w[aa kk agent-notification auto-reply], articles: %i[customer auto_reply notification])
          end
        end
      end
    end

    context 'when the auto reply trigger matches the state set by the agent notification trigger (auto reply check - recursive)' do
      before do
        create_auto_reply_trigger('001 auto reply', state: 'open')
        create_agent_notification_trigger('002 additional agent notification', set_state: 'open')
      end

      context 'with ticket_trigger_recursive false' do
        before { Setting.set('ticket_trigger_recursive', false) }

        include_examples 'running the agent notification only for a mail with auto-response headers', state: 'open'

        it 'does not send the auto reply' do
          ticket, mail = process_mail

          expect(mail[:'x-zammad-send-auto-response']).to be(true)
          expect_ticket(ticket, state: 'open', tags: %w[aa kk agent-notification], articles: %i[customer notification])
        end
      end

      context 'with ticket_trigger_recursive true' do
        before { Setting.set('ticket_trigger_recursive', true) }

        include_examples 'running the agent notification only for a mail with auto-response headers', state: 'open'

        it 'sends the auto reply after the agent notification' do
          ticket, mail = process_mail

          expect(mail[:'x-zammad-send-auto-response']).to be(true)
          expect_ticket(ticket, state: 'open', tags: %w[aa kk agent-notification auto-reply], articles: %i[customer notification auto_reply])
        end
      end
    end
  end
end
