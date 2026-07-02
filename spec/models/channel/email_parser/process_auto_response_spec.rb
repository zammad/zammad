# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Channel::EmailParser process with auto-response', performs_jobs: true, type: :model do

  describe 'auto-response and agent notification triggers', :aggregate_failures do
    before do
      Trigger.destroy_all # Default DB state includes three sample triggers
      create(:email_address) # gets auto-assigned to the sole existing group
    end

    it 'processes auto-response headers and fires the auto-reply after the agent notification when the auto-reply trigger is named "002 auto reply" (auto reply check - 1)' do # rubocop:disable RSpec/ExampleLength
      roles  = Role.where(name: 'Agent')
      agent1 = User.create!(
        login:         'ticket-auto-responder-agent1@example.com',
        firstname:     'AutoReponder',
        lastname:      'Agent1',
        email:         'ticket-auto-responder-agent1@example.com',
        password:      'agentpw',
        active:        true,
        roles:         roles,
        groups:        Group.all,
        updated_by_id: 1,
        created_by_id: 1,
      )

      Trigger.create!(
        name:                 '002 auto reply',
        condition:            {
          'ticket.action'   => {
            'operator' => 'is',
            'value'    => 'create',
          },
          'ticket.state_id' => {
            'operator' => 'is',
            'value'    => Ticket::State.lookup(name: 'new').id.to_s,
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

      email_raw_string = "From: me@example.com
To: customer@example.com
Subject: some new subject

Some Text"

      _ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
      expect(mail[:'x-zammad-send-auto-response']).to be(true)
      perform_enqueued_jobs
      expect(article_p.ticket.articles.count).to eq(2)

      email_raw_string = "From: me@example.com
To: customer@example.com
Subject: some new subject
X-Loop: yes

Some Text"

      _ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
      expect(mail[:'x-zammad-send-auto-response']).to be(false)
      perform_enqueued_jobs
      expect(article_p.ticket.articles.count).to eq(1)

      email_raw_string = "From: me@example.com
To: customer@example.com
Subject: some new subject
Precedence: Bulk

Some Text"

      _ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
      expect(mail[:'x-zammad-send-auto-response']).to be(false)

      email_raw_string = "From: me@example.com
To: customer@example.com
Subject: some new subject
Auto-Submitted: auto-generated

Some Text"
      perform_enqueued_jobs
      expect(article_p.ticket.articles.count).to eq(1)

      _ticket_p, _article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
      expect(mail[:'x-zammad-send-auto-response']).to be(false)

      email_raw_string = "From: me@example.com
To: customer@example.com
Subject: some new subject
X-Auto-Response-Suppress: All


Some Text"

      _ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
      expect(mail[:'x-zammad-send-auto-response']).to be(false)
      perform_enqueued_jobs
      expect(article_p.ticket.articles.count).to eq(1)

      fqdn = Setting.get('fqdn')
      email_raw_string = "From: me@example.com
To: customer@example.com
Subject: some new subject
Message-ID: <1234@#{fqdn}>

Some Text"

      _ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
      expect(mail[:'x-zammad-send-auto-response']).to be(false)
      perform_enqueued_jobs
      expect(article_p.ticket.articles.count).to eq(1)

      fqdn = Setting.get('fqdn')
      email_raw_string = "From: me@example.com
To: customer@example.com
Subject: some new subject
Message-ID: <1234@not_matching.#{fqdn}>

Some Text"

      _ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
      expect(mail[:'x-zammad-send-auto-response']).to be(true)
      perform_enqueued_jobs
      expect(article_p.ticket.articles.count).to eq(2)

      email_raw_string = "Return-Path: <XX@XX.XX>
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

      _ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
      expect(mail[:'x-zammad-send-auto-response']).to be(false)
      perform_enqueued_jobs
      expect(article_p.ticket.articles.count).to eq(1)

      # add an agent notification
      Trigger.create!(
        name:                 '001 additional agent notification',
        condition:            {
          'ticket.state_id' => {
            'operator' => 'is',
            'value'    => Ticket::State.lookup(name: 'new').id.to_s,
          }
        },
        perform:              {
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
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )

      email_raw_string = "From: me@example.com
To: customer@example.com
Subject: some new subject
X-Loop: yes

Some Text"

      ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
      expect(mail[:'x-zammad-send-auto-response']).to be(false)
      perform_enqueued_jobs

      tags = ticket_p.tag_list
      expect(ticket_p.state.name).to eq('new')
      expect(ticket_p.priority.name).to eq('3 high')
      expect(tags).to include('aa')
      expect(tags).to include('kk')
      expect(tags).to include('agent-notification')
      expect(tags.count).to eq(3)
      expect(article_p.ticket.articles.count).to eq(2)
      article_customer = article_p.ticket.articles.first
      expect(article_customer.from).to eq('me@example.com')
      expect(article_customer.to).to eq('customer@example.com')
      expect(article_customer.sender.name).to eq('Customer')
      expect(article_customer.type.name).to eq('email')
      article_notification = article_p.ticket.articles[1]
      expect(article_notification.subject).to match(%r{New Ticket add. info})
      expect(article_notification.to).not_to match(%r{me@example.com})
      expect(article_notification.to).to match(%r{#{agent1.email}})
      expect(article_notification.sender.name).to eq('System')
      expect(article_notification.type.name).to eq('email')

      Setting.set('ticket_trigger_recursive', true)

      ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
      expect(mail[:'x-zammad-send-auto-response']).to be(false)
      perform_enqueued_jobs

      tags = ticket_p.tag_list
      expect(ticket_p.state.name).to eq('new')
      expect(ticket_p.priority.name).to eq('3 high')
      expect(tags).to include('aa')
      expect(tags).to include('kk')
      expect(tags).to include('agent-notification')
      expect(tags.count).to eq(3)
      expect(article_p.ticket.articles.count).to eq(2)
      article_customer = article_p.ticket.articles.first
      expect(article_customer.from).to eq('me@example.com')
      expect(article_customer.to).to eq('customer@example.com')
      expect(article_customer.sender.name).to eq('Customer')
      expect(article_customer.type.name).to eq('email')
      article_notification = article_p.ticket.articles[1]
      expect(article_notification.subject).to match(%r{New Ticket add. info})
      expect(article_notification.to).not_to match(%r{me@example.com})
      expect(article_notification.to).to match(%r{#{agent1.email}})
      expect(article_notification.sender.name).to eq('System')
      expect(article_notification.type.name).to eq('email')

      Setting.set('ticket_trigger_recursive', false)

      email_raw_string = "From: me@example.com
To: customer@example.com
Subject: some new subject

Some Text"

      ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
      expect(mail[:'x-zammad-send-auto-response']).to be(true)
      perform_enqueued_jobs

      tags = ticket_p.tag_list
      expect(ticket_p.state.name).to eq('new')
      expect(ticket_p.priority.name).to eq('3 high')
      expect(tags).to include('aa')
      expect(tags).to include('kk')
      expect(tags).to include('agent-notification')
      expect(tags).to include('auto-reply')
      expect(article_p.ticket.articles.count).to eq(3)
      article_customer = article_p.ticket.articles[0]
      expect(article_customer.from).to eq('me@example.com')
      expect(article_customer.to).to eq('customer@example.com')
      expect(article_customer.sender.name).to eq('Customer')
      expect(article_customer.type.name).to eq('email')
      article_notification = article_p.ticket.articles[1]
      expect(article_notification.subject).to match(%r{New Ticket add. info})
      expect(article_notification.to).not_to match(%r{me@example.com})
      expect(article_notification.to).to match(%r{#{agent1.email}})
      expect(article_notification.sender.name).to eq('System')
      expect(article_notification.type.name).to eq('email')
      article_auto_reply = article_p.ticket.articles[2]
      expect(article_auto_reply.subject).to include('Thanks for your inquiry')
      expect(article_auto_reply.to).to match(%r{me@example.com})
      expect(article_auto_reply.sender.name).to eq('System')
      expect(article_auto_reply.type.name).to eq('email')

      Setting.set('ticket_trigger_recursive', true)

      ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
      expect(mail[:'x-zammad-send-auto-response']).to be(true)
      perform_enqueued_jobs
      tags = ticket_p.tag_list
      expect(ticket_p.state.name).to eq('new')
      expect(ticket_p.priority.name).to eq('3 high')
      expect(tags).to include('aa')
      expect(tags).to include('kk')
      expect(tags).to include('agent-notification')
      expect(tags).to include('auto-reply')
      expect(article_p.ticket.articles.count).to eq(3)
      article_customer = article_p.ticket.articles[0]
      expect(article_customer.from).to eq('me@example.com')
      expect(article_customer.to).to eq('customer@example.com')
      expect(article_customer.sender.name).to eq('Customer')
      expect(article_customer.type.name).to eq('email')
      article_notification = article_p.ticket.articles[1]
      expect(article_notification.subject).to match(%r{New Ticket add. info})
      expect(article_notification.to).not_to match(%r{me@example.com})
      expect(article_notification.to).to match(%r{#{agent1.email}})
      expect(article_notification.sender.name).to eq('System')
      expect(article_notification.type.name).to eq('email')
      article_auto_reply = article_p.ticket.articles[2]
      expect(article_auto_reply.subject).to include('Thanks for your inquiry')
      expect(article_auto_reply.to).to match(%r{me@example.com})
      expect(article_auto_reply.sender.name).to eq('System')
      expect(article_auto_reply.type.name).to eq('email')
    end

    it 'processes auto-response headers and fires the auto-reply before the agent notification when the auto-reply trigger is named "001 auto reply" (auto reply check - 2)' do # rubocop:disable RSpec/ExampleLength
      roles  = Role.where(name: 'Agent')
      agent1 = User.create!(
        login:         'ticket-auto-responder-agent1@example.com',
        firstname:     'AutoReponder',
        lastname:      'Agent1',
        email:         'ticket-auto-responder-agent1@example.com',
        password:      'agentpw',
        active:        true,
        roles:         roles,
        groups:        Group.all,
        updated_by_id: 1,
        created_by_id: 1,
      )

      Trigger.create!(
        name:                 '001 auto reply',
        condition:            {
          'ticket.action'   => {
            'operator' => 'is',
            'value'    => 'create',
          },
          'ticket.state_id' => {
            'operator' => 'is',
            'value'    => Ticket::State.lookup(name: 'new').id.to_s,
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

      email_raw_string = "From: me@example.com
To: customer@example.com
Subject: some new subject

Some Text"

      _ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
      expect(mail[:'x-zammad-send-auto-response']).to be(true)
      perform_enqueued_jobs
      expect(article_p.ticket.articles.count).to eq(2)

      email_raw_string = "From: me@example.com
To: customer@example.com
Subject: some new subject
X-Loop: yes

Some Text"

      _ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
      expect(mail[:'x-zammad-send-auto-response']).to be(false)
      perform_enqueued_jobs
      expect(article_p.ticket.articles.count).to eq(1)

      email_raw_string = "From: me@example.com
To: customer@example.com
Subject: some new subject
Precedence: Bulk

Some Text"

      _ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
      expect(mail[:'x-zammad-send-auto-response']).to be(false)

      email_raw_string = "From: me@example.com
To: customer@example.com
Subject: some new subject
Auto-Submitted: auto-generated

Some Text"
      perform_enqueued_jobs
      expect(article_p.ticket.articles.count).to eq(1)

      _ticket_p, _article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
      expect(mail[:'x-zammad-send-auto-response']).to be(false)

      email_raw_string = "From: me@example.com
To: customer@example.com
Subject: some new subject
X-Auto-Response-Suppress: All


Some Text"

      _ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
      expect(mail[:'x-zammad-send-auto-response']).to be(false)
      perform_enqueued_jobs
      expect(article_p.ticket.articles.count).to eq(1)

      fqdn = Setting.get('fqdn')
      email_raw_string = "From: me@example.com
To: customer@example.com
Subject: some new subject
Message-ID: <1234@#{fqdn}>

Some Text"

      _ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
      expect(mail[:'x-zammad-send-auto-response']).to be(false)
      perform_enqueued_jobs
      expect(article_p.ticket.articles.count).to eq(1)

      fqdn = Setting.get('fqdn')
      email_raw_string = "From: me@example.com
To: customer@example.com
Subject: some new subject
Message-ID: <1234@not_matching.#{fqdn}>

Some Text"

      _ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
      expect(mail[:'x-zammad-send-auto-response']).to be(true)
      perform_enqueued_jobs
      expect(article_p.ticket.articles.count).to eq(2)

      email_raw_string = "Return-Path: <XX@XX.XX>
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

      _ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
      expect(mail[:'x-zammad-send-auto-response']).to be(false)
      perform_enqueued_jobs
      expect(article_p.ticket.articles.count).to eq(1)

      # add an agent notification
      Trigger.create!(
        name:                 '002 additional agent notification',
        condition:            {
          'ticket.state_id' => {
            'operator' => 'is',
            'value'    => Ticket::State.lookup(name: 'new').id.to_s,
          }
        },
        perform:              {
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
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )

      email_raw_string = "From: me@example.com
To: customer@example.com
Subject: some new subject
X-Loop: yes

Some Text"

      ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
      expect(mail[:'x-zammad-send-auto-response']).to be(false)
      perform_enqueued_jobs

      tags = ticket_p.tag_list
      expect(ticket_p.state.name).to eq('new')
      expect(ticket_p.priority.name).to eq('3 high')
      expect(tags).to include('aa')
      expect(tags).to include('kk')
      expect(tags).to include('agent-notification')
      expect(tags.count).to eq(3)
      expect(article_p.ticket.articles.count).to eq(2)
      article_customer = article_p.ticket.articles.first
      expect(article_customer.from).to eq('me@example.com')
      expect(article_customer.to).to eq('customer@example.com')
      expect(article_customer.sender.name).to eq('Customer')
      expect(article_customer.type.name).to eq('email')
      article_notification = article_p.ticket.articles[1]
      expect(article_notification.subject).to match(%r{New Ticket add. info})
      expect(article_notification.to).not_to match(%r{me@example.com})
      expect(article_notification.to).to match(%r{#{agent1.email}})
      expect(article_notification.sender.name).to eq('System')
      expect(article_notification.type.name).to eq('email')

      Setting.set('ticket_trigger_recursive', true)

      ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
      expect(mail[:'x-zammad-send-auto-response']).to be(false)
      perform_enqueued_jobs

      tags = ticket_p.tag_list
      expect(ticket_p.state.name).to eq('new')
      expect(ticket_p.priority.name).to eq('3 high')
      expect(tags).to include('aa')
      expect(tags).to include('kk')
      expect(tags).to include('agent-notification')
      expect(tags.count).to eq(3)
      expect(article_p.ticket.articles.count).to eq(2)
      article_customer = article_p.ticket.articles.first
      expect(article_customer.from).to eq('me@example.com')
      expect(article_customer.to).to eq('customer@example.com')
      expect(article_customer.sender.name).to eq('Customer')
      expect(article_customer.type.name).to eq('email')
      article_notification = article_p.ticket.articles[1]
      expect(article_notification.subject).to match(%r{New Ticket add. info})
      expect(article_notification.to).not_to match(%r{me@example.com})
      expect(article_notification.to).to match(%r{#{agent1.email}})
      expect(article_notification.sender.name).to eq('System')
      expect(article_notification.type.name).to eq('email')

      Setting.set('ticket_trigger_recursive', false)

      email_raw_string = "From: me@example.com
To: customer@example.com
Subject: some new subject

Some Text"

      ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
      expect(mail[:'x-zammad-send-auto-response']).to be(true)
      perform_enqueued_jobs

      tags = ticket_p.tag_list
      expect(ticket_p.state.name).to eq('new')
      expect(ticket_p.priority.name).to eq('3 high')
      expect(tags).to include('aa')
      expect(tags).to include('kk')
      expect(tags).to include('agent-notification')
      expect(tags).to include('auto-reply')
      expect(article_p.ticket.articles.count).to eq(3)
      article_customer = article_p.ticket.articles[0]
      expect(article_customer.from).to eq('me@example.com')
      expect(article_customer.to).to eq('customer@example.com')
      expect(article_customer.sender.name).to eq('Customer')
      expect(article_customer.type.name).to eq('email')
      article_auto_reply = article_p.ticket.articles[1]
      expect(article_auto_reply.subject).to include('Thanks for your inquiry')
      expect(article_auto_reply.to).to match(%r{me@example.com})
      expect(article_auto_reply.sender.name).to eq('System')
      expect(article_auto_reply.type.name).to eq('email')
      article_notification = article_p.ticket.articles[2]
      expect(article_notification.subject).to match(%r{New Ticket add. info})
      expect(article_notification.to).not_to match(%r{me@example.com})
      expect(article_notification.to).to match(%r{#{agent1.email}})
      expect(article_notification.sender.name).to eq('System')
      expect(article_notification.type.name).to eq('email')

      Setting.set('ticket_trigger_recursive', true)

      ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
      expect(mail[:'x-zammad-send-auto-response']).to be(true)
      perform_enqueued_jobs
      tags = ticket_p.tag_list
      expect(ticket_p.state.name).to eq('new')
      expect(ticket_p.priority.name).to eq('3 high')
      expect(tags).to include('aa')
      expect(tags).to include('kk')
      expect(tags).to include('agent-notification')
      expect(tags).to include('auto-reply')
      expect(article_p.ticket.articles.count).to eq(3)
      article_customer = article_p.ticket.articles[0]
      expect(article_customer.from).to eq('me@example.com')
      expect(article_customer.to).to eq('customer@example.com')
      expect(article_customer.sender.name).to eq('Customer')
      expect(article_customer.type.name).to eq('email')
      article_auto_reply = article_p.ticket.articles[1]
      expect(article_auto_reply.subject).to include('Thanks for your inquiry')
      expect(article_auto_reply.to).to match(%r{me@example.com})
      expect(article_auto_reply.sender.name).to eq('System')
      expect(article_auto_reply.type.name).to eq('email')
      article_notification = article_p.ticket.articles[2]
      expect(article_notification.subject).to match(%r{New Ticket add. info})
      expect(article_notification.to).not_to match(%r{me@example.com})
      expect(article_notification.to).to match(%r{#{agent1.email}})
      expect(article_notification.sender.name).to eq('System')
      expect(article_notification.type.name).to eq('email')
    end

    it 'processes auto-response headers and fires the auto-reply after the agent notification when both triggers apply to the same "new" ticket state (auto reply check - recursive)' do # rubocop:disable RSpec/ExampleLength
      roles  = Role.where(name: 'Agent')
      agent1 = User.create!(
        login:         'ticket-auto-responder-agent1@example.com',
        firstname:     'AutoReponder',
        lastname:      'Agent1',
        email:         'ticket-auto-responder-agent1@example.com',
        password:      'agentpw',
        active:        true,
        roles:         roles,
        groups:        Group.all,
        updated_by_id: 1,
        created_by_id: 1,
      )

      Trigger.create!(
        name:                 '001 auto reply',
        condition:            {
          'ticket.action'   => {
            'operator' => 'is',
            'value'    => 'create',
          },
          'ticket.state_id' => {
            'operator' => 'is',
            'value'    => Ticket::State.lookup(name: 'open').id.to_s,
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

      # add an agent notification
      Trigger.create!(
        name:                 '002 additional agent notification',
        condition:            {
          'ticket.state_id' => {
            'operator' => 'is',
            'value'    => Ticket::State.lookup(name: 'new').id.to_s,
          }
        },
        perform:              {
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
          'ticket.state_id'    => {
            'value' => Ticket::State.lookup(name: 'open').id.to_s,
          },
          'ticket.tags'        => {
            'operator' => 'add',
            'value'    => 'aa, kk, agent-notification',
          },
        },
        disable_notification: true,
        active:               true,
        created_by_id:        1,
        updated_by_id:        1,
      )

      email_raw_string = "From: me@example.com
To: customer@example.com
Subject: some new subject
X-Loop: yes

Some Text"

      ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
      expect(mail[:'x-zammad-send-auto-response']).to be(false)
      perform_enqueued_jobs

      tags = ticket_p.tag_list
      expect(ticket_p.state.name).to eq('open')
      expect(ticket_p.priority.name).to eq('3 high')
      expect(tags).to include('aa')
      expect(tags).to include('kk')
      expect(tags).to include('agent-notification')
      expect(tags.count).to eq(3)
      expect(article_p.ticket.articles.count).to eq(2)
      article_customer = article_p.ticket.articles.first
      expect(article_customer.from).to eq('me@example.com')
      expect(article_customer.to).to eq('customer@example.com')
      expect(article_customer.sender.name).to eq('Customer')
      expect(article_customer.type.name).to eq('email')
      article_notification = article_p.ticket.articles[1]
      expect(article_notification.subject).to match(%r{New Ticket add. info})
      expect(article_notification.to).not_to match(%r{me@example.com})
      expect(article_notification.to).to match(%r{#{agent1.email}})
      expect(article_notification.sender.name).to eq('System')
      expect(article_notification.type.name).to eq('email')

      Setting.set('ticket_trigger_recursive', true)

      ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
      expect(mail[:'x-zammad-send-auto-response']).to be(false)
      perform_enqueued_jobs

      tags = ticket_p.tag_list
      expect(ticket_p.state.name).to eq('open')
      expect(ticket_p.priority.name).to eq('3 high')
      expect(tags).to include('aa')
      expect(tags).to include('kk')
      expect(tags).to include('agent-notification')
      expect(tags.count).to eq(3)
      expect(article_p.ticket.articles.count).to eq(2)
      article_customer = article_p.ticket.articles.first
      expect(article_customer.from).to eq('me@example.com')
      expect(article_customer.to).to eq('customer@example.com')
      expect(article_customer.sender.name).to eq('Customer')
      expect(article_customer.type.name).to eq('email')
      article_notification = article_p.ticket.articles[1]
      expect(article_notification.subject).to match(%r{New Ticket add. info})
      expect(article_notification.to).not_to match(%r{me@example.com})
      expect(article_notification.to).to match(%r{#{agent1.email}})
      expect(article_notification.sender.name).to eq('System')
      expect(article_notification.type.name).to eq('email')

      Setting.set('ticket_trigger_recursive', false)

      email_raw_string = "From: me@example.com
To: customer@example.com
Subject: some new subject

Some Text"

      ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
      expect(mail[:'x-zammad-send-auto-response']).to be(true)
      perform_enqueued_jobs

      tags = ticket_p.tag_list
      expect(ticket_p.state.name).to eq('open')
      expect(ticket_p.priority.name).to eq('3 high')
      expect(tags).to include('aa')
      expect(tags).to include('kk')
      expect(tags).to include('agent-notification')
      expect(article_p.ticket.articles.count).to eq(2)
      article_customer = article_p.ticket.articles[0]
      expect(article_customer.from).to eq('me@example.com')
      expect(article_customer.to).to eq('customer@example.com')
      expect(article_customer.sender.name).to eq('Customer')
      expect(article_customer.type.name).to eq('email')
      article_notification = article_p.ticket.articles[1]
      expect(article_notification.subject).to match(%r{New Ticket add. info})
      expect(article_notification.to).not_to match(%r{me@example.com})
      expect(article_notification.to).to match(%r{#{agent1.email}})
      expect(article_notification.sender.name).to eq('System')
      expect(article_notification.type.name).to eq('email')

      Setting.set('ticket_trigger_recursive', true)

      ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
      expect(mail[:'x-zammad-send-auto-response']).to be(true)
      perform_enqueued_jobs
      tags = ticket_p.tag_list
      expect(ticket_p.state.name).to eq('open')
      expect(ticket_p.priority.name).to eq('3 high')
      expect(tags).to include('aa')
      expect(tags).to include('kk')
      expect(tags).to include('agent-notification')
      expect(tags).to include('auto-reply')
      expect(article_p.ticket.articles.count).to eq(3)
      article_customer = article_p.ticket.articles[0]
      expect(article_customer.from).to eq('me@example.com')
      expect(article_customer.to).to eq('customer@example.com')
      expect(article_customer.sender.name).to eq('Customer')
      expect(article_customer.type.name).to eq('email')
      article_notification = article_p.ticket.articles[1]
      expect(article_notification.subject).to match(%r{New Ticket add. info})
      expect(article_notification.to).not_to match(%r{me@example.com})
      expect(article_notification.to).to match(%r{#{agent1.email}})
      expect(article_notification.sender.name).to eq('System')
      expect(article_notification.type.name).to eq('email')
      article_auto_reply = article_p.ticket.articles[2]
      expect(article_auto_reply.subject).to include('Thanks for your inquiry')
      expect(article_auto_reply.to).to match(%r{me@example.com})
      expect(article_auto_reply.sender.name).to eq('System')
      expect(article_auto_reply.type.name).to eq('email')
    end
  end
end
