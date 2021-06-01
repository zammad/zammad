# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'test_helper'

class EmailProcessAutoResponseTest < ActiveSupport::TestCase

  test 'process auto reply check - 1' do

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
          'body'      => 'some text<br>#{ticket.customer.lastname}<br>#{ticket.title}',
          'recipient' => 'ticket_customer',
          'subject'   => 'Thanks for your inquiry (#{ticket.title})!',
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
    assert_equal(true, mail[:'x-zammad-send-auto-response'])
    Scheduler.worker(true)
    assert_equal(2, article_p.ticket.articles.count)

    email_raw_string = "From: me@example.com
To: customer@example.com
Subject: some new subject
X-Loop: yes

Some Text"

    _ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal(false, mail[:'x-zammad-send-auto-response'])
    Scheduler.worker(true)
    assert_equal(1, article_p.ticket.articles.count)

    email_raw_string = "From: me@example.com
To: customer@example.com
Subject: some new subject
Precedence: Bulk

Some Text"

    _ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal(false, mail[:'x-zammad-send-auto-response'])

    email_raw_string = "From: me@example.com
To: customer@example.com
Subject: some new subject
Auto-Submitted: auto-generated

Some Text"
    Scheduler.worker(true)
    assert_equal(1, article_p.ticket.articles.count)

    _ticket_p, _article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal(false, mail[:'x-zammad-send-auto-response'])

    email_raw_string = "From: me@example.com
To: customer@example.com
Subject: some new subject
X-Auto-Response-Suppress: All


Some Text"

    _ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal(false, mail[:'x-zammad-send-auto-response'])
    Scheduler.worker(true)
    assert_equal(1, article_p.ticket.articles.count)

    fqdn = Setting.get('fqdn')
    email_raw_string = "From: me@example.com
To: customer@example.com
Subject: some new subject
Message-ID: <1234@#{fqdn}>

Some Text"

    _ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal(false, mail[:'x-zammad-send-auto-response'])
    Scheduler.worker(true)
    assert_equal(1, article_p.ticket.articles.count)

    fqdn = Setting.get('fqdn')
    email_raw_string = "From: me@example.com
To: customer@example.com
Subject: some new subject
Message-ID: <1234@not_matching.#{fqdn}>

Some Text"

    _ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal(true, mail[:'x-zammad-send-auto-response'])
    Scheduler.worker(true)
    assert_equal(2, article_p.ticket.articles.count)

    email_raw_string = "Return-Path: <XX@XX.XX>
X-Original-To: sales@znuny.com
Received: from mail-qk0-f170.example.com (mail-qk0-f170.example.com [209.1.1.1])
    by arber.znuny.com (Postfix) with ESMTPS id C3AED5FE2E
    for <sales@znuny.com>; Mon, 22 Aug 2016 19:03:15 +0200 (CEST)
Received: by mail-qk0-f170.example.com with SMTP id t7so87721720qkh.1
        for <sales@znuny.com>; Mon, 22 Aug 2016 10:03:15 -0700 (PDT)
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
To: sales@znuny.com
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
    assert_equal(false, mail[:'x-zammad-send-auto-response'])
    Scheduler.worker(true)
    assert_equal(1, article_p.ticket.articles.count)

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
          'body'      => 'some text<br>#{ticket.customer.lastname}<br>#{ticket.title}',
          'recipient' => 'ticket_agents',
          'subject'   => 'New Ticket add. info (#{ticket.title})!',
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
    assert_equal(false, mail[:'x-zammad-send-auto-response'])
    Scheduler.worker(true)

    tags = ticket_p.tag_list
    assert_equal('new', ticket_p.state.name)
    assert_equal('3 high', ticket_p.priority.name)
    assert(tags.include?('aa'))
    assert(tags.include?('kk'))
    assert(tags.include?('agent-notification'))
    assert_equal(3, tags.count)
    assert_equal(2, article_p.ticket.articles.count)
    article_customer = article_p.ticket.articles.first
    assert_equal('me@example.com', article_customer.from)
    assert_equal('customer@example.com', article_customer.to)
    assert_equal('Customer', article_customer.sender.name)
    assert_equal('email', article_customer.type.name)
    article_notification = article_p.ticket.articles[1]
    assert_match(%r{New Ticket add. info}, article_notification.subject)
    assert_no_match(%r{me@example.com}, article_notification.to)
    assert_match(%r{#{agent1.email}}, article_notification.to)
    assert_equal('System', article_notification.sender.name)
    assert_equal('email', article_notification.type.name)

    Setting.set('ticket_trigger_recursive', true)

    ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal(false, mail[:'x-zammad-send-auto-response'])
    Scheduler.worker(true)

    tags = ticket_p.tag_list
    assert_equal('new', ticket_p.state.name)
    assert_equal('3 high', ticket_p.priority.name)
    assert(tags.include?('aa'))
    assert(tags.include?('kk'))
    assert(tags.include?('agent-notification'))
    assert_equal(3, tags.count)
    assert_equal(2, article_p.ticket.articles.count)
    article_customer = article_p.ticket.articles.first
    assert_equal('me@example.com', article_customer.from)
    assert_equal('customer@example.com', article_customer.to)
    assert_equal('Customer', article_customer.sender.name)
    assert_equal('email', article_customer.type.name)
    article_notification = article_p.ticket.articles[1]
    assert_match(%r{New Ticket add. info}, article_notification.subject)
    assert_no_match(%r{me@example.com}, article_notification.to)
    assert_match(%r{#{agent1.email}}, article_notification.to)
    assert_equal('System', article_notification.sender.name)
    assert_equal('email', article_notification.type.name)

    Setting.set('ticket_trigger_recursive', false)

    email_raw_string = "From: me@example.com
To: customer@example.com
Subject: some new subject

Some Text"

    ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal(true, mail[:'x-zammad-send-auto-response'])
    Scheduler.worker(true)

    tags = ticket_p.tag_list
    assert_equal('new', ticket_p.state.name)
    assert_equal('3 high', ticket_p.priority.name)
    assert(tags.include?('aa'))
    assert(tags.include?('kk'))
    assert(tags.include?('agent-notification'))
    assert(tags.include?('auto-reply'))
    assert_equal(3, article_p.ticket.articles.count)
    article_customer = article_p.ticket.articles[0]
    assert_equal('me@example.com', article_customer.from)
    assert_equal('customer@example.com', article_customer.to)
    assert_equal('Customer', article_customer.sender.name)
    assert_equal('email', article_customer.type.name)
    article_notification = article_p.ticket.articles[1]
    assert_match(%r{New Ticket add. info}, article_notification.subject)
    assert_no_match(%r{me@example.com}, article_notification.to)
    assert_match(%r{#{agent1.email}}, article_notification.to)
    assert_equal('System', article_notification.sender.name)
    assert_equal('email', article_notification.type.name)
    article_auto_reply = article_p.ticket.articles[2]
    assert_match(%r{Thanks for your inquiry}, article_auto_reply.subject)
    assert_match(%r{me@example.com}, article_auto_reply.to)
    assert_equal('System', article_auto_reply.sender.name)
    assert_equal('email', article_auto_reply.type.name)

    Setting.set('ticket_trigger_recursive', true)

    ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal(true, mail[:'x-zammad-send-auto-response'])
    Scheduler.worker(true)
    tags = ticket_p.tag_list
    assert_equal('new', ticket_p.state.name)
    assert_equal('3 high', ticket_p.priority.name)
    assert(tags.include?('aa'))
    assert(tags.include?('kk'))
    assert(tags.include?('agent-notification'))
    assert(tags.include?('auto-reply'))
    assert_equal(3, article_p.ticket.articles.count)
    article_customer = article_p.ticket.articles[0]
    assert_equal('me@example.com', article_customer.from)
    assert_equal('customer@example.com', article_customer.to)
    assert_equal('Customer', article_customer.sender.name)
    assert_equal('email', article_customer.type.name)
    article_notification = article_p.ticket.articles[1]
    assert_match(%r{New Ticket add. info}, article_notification.subject)
    assert_no_match(%r{me@example.com}, article_notification.to)
    assert_match(%r{#{agent1.email}}, article_notification.to)
    assert_equal('System', article_notification.sender.name)
    assert_equal('email', article_notification.type.name)
    article_auto_reply = article_p.ticket.articles[2]
    assert_match(%r{Thanks for your inquiry}, article_auto_reply.subject)
    assert_match(%r{me@example.com}, article_auto_reply.to)
    assert_equal('System', article_auto_reply.sender.name)
    assert_equal('email', article_auto_reply.type.name)

  end

  test 'process auto reply check - 2' do

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
          'body'      => 'some text<br>#{ticket.customer.lastname}<br>#{ticket.title}',
          'recipient' => 'ticket_customer',
          'subject'   => 'Thanks for your inquiry (#{ticket.title})!',
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
    assert_equal(true, mail[:'x-zammad-send-auto-response'])
    Scheduler.worker(true)
    assert_equal(2, article_p.ticket.articles.count)

    email_raw_string = "From: me@example.com
To: customer@example.com
Subject: some new subject
X-Loop: yes

Some Text"

    _ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal(false, mail[:'x-zammad-send-auto-response'])
    Scheduler.worker(true)
    assert_equal(1, article_p.ticket.articles.count)

    email_raw_string = "From: me@example.com
To: customer@example.com
Subject: some new subject
Precedence: Bulk

Some Text"

    _ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal(false, mail[:'x-zammad-send-auto-response'])

    email_raw_string = "From: me@example.com
To: customer@example.com
Subject: some new subject
Auto-Submitted: auto-generated

Some Text"
    Scheduler.worker(true)
    assert_equal(1, article_p.ticket.articles.count)

    _ticket_p, _article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal(false, mail[:'x-zammad-send-auto-response'])

    email_raw_string = "From: me@example.com
To: customer@example.com
Subject: some new subject
X-Auto-Response-Suppress: All


Some Text"

    _ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal(false, mail[:'x-zammad-send-auto-response'])
    Scheduler.worker(true)
    assert_equal(1, article_p.ticket.articles.count)

    fqdn = Setting.get('fqdn')
    email_raw_string = "From: me@example.com
To: customer@example.com
Subject: some new subject
Message-ID: <1234@#{fqdn}>

Some Text"

    _ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal(false, mail[:'x-zammad-send-auto-response'])
    Scheduler.worker(true)
    assert_equal(1, article_p.ticket.articles.count)

    fqdn = Setting.get('fqdn')
    email_raw_string = "From: me@example.com
To: customer@example.com
Subject: some new subject
Message-ID: <1234@not_matching.#{fqdn}>

Some Text"

    _ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal(true, mail[:'x-zammad-send-auto-response'])
    Scheduler.worker(true)
    assert_equal(2, article_p.ticket.articles.count)

    email_raw_string = "Return-Path: <XX@XX.XX>
X-Original-To: sales@znuny.com
Received: from mail-qk0-f170.example.com (mail-qk0-f170.example.com [209.1.1.1])
    by arber.znuny.com (Postfix) with ESMTPS id C3AED5FE2E
    for <sales@znuny.com>; Mon, 22 Aug 2016 19:03:15 +0200 (CEST)
Received: by mail-qk0-f170.example.com with SMTP id t7so87721720qkh.1
        for <sales@znuny.com>; Mon, 22 Aug 2016 10:03:15 -0700 (PDT)
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
To: sales@znuny.com
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
    assert_equal(false, mail[:'x-zammad-send-auto-response'])
    Scheduler.worker(true)
    assert_equal(1, article_p.ticket.articles.count)

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
          'body'      => 'some text<br>#{ticket.customer.lastname}<br>#{ticket.title}',
          'recipient' => 'ticket_agents',
          'subject'   => 'New Ticket add. info (#{ticket.title})!',
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
    assert_equal(false, mail[:'x-zammad-send-auto-response'])
    Scheduler.worker(true)

    tags = ticket_p.tag_list
    assert_equal('new', ticket_p.state.name)
    assert_equal('3 high', ticket_p.priority.name)
    assert(tags.include?('aa'))
    assert(tags.include?('kk'))
    assert(tags.include?('agent-notification'))
    assert_equal(3, tags.count)
    assert_equal(2, article_p.ticket.articles.count)
    article_customer = article_p.ticket.articles.first
    assert_equal('me@example.com', article_customer.from)
    assert_equal('customer@example.com', article_customer.to)
    assert_equal('Customer', article_customer.sender.name)
    assert_equal('email', article_customer.type.name)
    article_notification = article_p.ticket.articles[1]
    assert_match(%r{New Ticket add. info}, article_notification.subject)
    assert_no_match(%r{me@example.com}, article_notification.to)
    assert_match(%r{#{agent1.email}}, article_notification.to)
    assert_equal('System', article_notification.sender.name)
    assert_equal('email', article_notification.type.name)

    Setting.set('ticket_trigger_recursive', true)

    ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal(false, mail[:'x-zammad-send-auto-response'])
    Scheduler.worker(true)

    tags = ticket_p.tag_list
    assert_equal('new', ticket_p.state.name)
    assert_equal('3 high', ticket_p.priority.name)
    assert(tags.include?('aa'))
    assert(tags.include?('kk'))
    assert(tags.include?('agent-notification'))
    assert_equal(3, tags.count)
    assert_equal(2, article_p.ticket.articles.count)
    article_customer = article_p.ticket.articles.first
    assert_equal('me@example.com', article_customer.from)
    assert_equal('customer@example.com', article_customer.to)
    assert_equal('Customer', article_customer.sender.name)
    assert_equal('email', article_customer.type.name)
    article_notification = article_p.ticket.articles[1]
    assert_match(%r{New Ticket add. info}, article_notification.subject)
    assert_no_match(%r{me@example.com}, article_notification.to)
    assert_match(%r{#{agent1.email}}, article_notification.to)
    assert_equal('System', article_notification.sender.name)
    assert_equal('email', article_notification.type.name)

    Setting.set('ticket_trigger_recursive', false)

    email_raw_string = "From: me@example.com
To: customer@example.com
Subject: some new subject

Some Text"

    ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal(true, mail[:'x-zammad-send-auto-response'])
    Scheduler.worker(true)

    tags = ticket_p.tag_list
    assert_equal('new', ticket_p.state.name)
    assert_equal('3 high', ticket_p.priority.name)
    assert(tags.include?('aa'))
    assert(tags.include?('kk'))
    assert(tags.include?('agent-notification'))
    assert(tags.include?('auto-reply'))
    assert_equal(3, article_p.ticket.articles.count)
    article_customer = article_p.ticket.articles[0]
    assert_equal('me@example.com', article_customer.from)
    assert_equal('customer@example.com', article_customer.to)
    assert_equal('Customer', article_customer.sender.name)
    assert_equal('email', article_customer.type.name)
    article_auto_reply = article_p.ticket.articles[1]
    assert_match(%r{Thanks for your inquiry}, article_auto_reply.subject)
    assert_match(%r{me@example.com}, article_auto_reply.to)
    assert_equal('System', article_auto_reply.sender.name)
    assert_equal('email', article_auto_reply.type.name)
    article_notification = article_p.ticket.articles[2]
    assert_match(%r{New Ticket add. info}, article_notification.subject)
    assert_no_match(%r{me@example.com}, article_notification.to)
    assert_match(%r{#{agent1.email}}, article_notification.to)
    assert_equal('System', article_notification.sender.name)
    assert_equal('email', article_notification.type.name)

    Setting.set('ticket_trigger_recursive', true)

    ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal(true, mail[:'x-zammad-send-auto-response'])
    Scheduler.worker(true)
    tags = ticket_p.tag_list
    assert_equal('new', ticket_p.state.name)
    assert_equal('3 high', ticket_p.priority.name)
    assert(tags.include?('aa'))
    assert(tags.include?('kk'))
    assert(tags.include?('agent-notification'))
    assert(tags.include?('auto-reply'))
    assert_equal(3, article_p.ticket.articles.count)
    article_customer = article_p.ticket.articles[0]
    assert_equal('me@example.com', article_customer.from)
    assert_equal('customer@example.com', article_customer.to)
    assert_equal('Customer', article_customer.sender.name)
    assert_equal('email', article_customer.type.name)
    article_auto_reply = article_p.ticket.articles[1]
    assert_match(%r{Thanks for your inquiry}, article_auto_reply.subject)
    assert_match(%r{me@example.com}, article_auto_reply.to)
    assert_equal('System', article_auto_reply.sender.name)
    assert_equal('email', article_auto_reply.type.name)
    article_notification = article_p.ticket.articles[2]
    assert_match(%r{New Ticket add. info}, article_notification.subject)
    assert_no_match(%r{me@example.com}, article_notification.to)
    assert_match(%r{#{agent1.email}}, article_notification.to)
    assert_equal('System', article_notification.sender.name)
    assert_equal('email', article_notification.type.name)

  end

  test 'process auto reply check - recursive' do

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
          'body'      => 'some text<br>#{ticket.customer.lastname}<br>#{ticket.title}',
          'recipient' => 'ticket_customer',
          'subject'   => 'Thanks for your inquiry (#{ticket.title})!',
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
          'body'      => 'some text<br>#{ticket.customer.lastname}<br>#{ticket.title}',
          'recipient' => 'ticket_agents',
          'subject'   => 'New Ticket add. info (#{ticket.title})!',
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
    assert_equal(false, mail[:'x-zammad-send-auto-response'])
    Scheduler.worker(true)

    tags = ticket_p.tag_list
    assert_equal('open', ticket_p.state.name)
    assert_equal('3 high', ticket_p.priority.name)
    assert(tags.include?('aa'))
    assert(tags.include?('kk'))
    assert(tags.include?('agent-notification'))
    assert_equal(3, tags.count)
    assert_equal(2, article_p.ticket.articles.count)
    article_customer = article_p.ticket.articles.first
    assert_equal('me@example.com', article_customer.from)
    assert_equal('customer@example.com', article_customer.to)
    assert_equal('Customer', article_customer.sender.name)
    assert_equal('email', article_customer.type.name)
    article_notification = article_p.ticket.articles[1]
    assert_match(%r{New Ticket add. info}, article_notification.subject)
    assert_no_match(%r{me@example.com}, article_notification.to)
    assert_match(%r{#{agent1.email}}, article_notification.to)
    assert_equal('System', article_notification.sender.name)
    assert_equal('email', article_notification.type.name)

    Setting.set('ticket_trigger_recursive', true)

    ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal(false, mail[:'x-zammad-send-auto-response'])
    Scheduler.worker(true)

    tags = ticket_p.tag_list
    assert_equal('open', ticket_p.state.name)
    assert_equal('3 high', ticket_p.priority.name)
    assert(tags.include?('aa'))
    assert(tags.include?('kk'))
    assert(tags.include?('agent-notification'))
    assert_equal(3, tags.count)
    assert_equal(2, article_p.ticket.articles.count)
    article_customer = article_p.ticket.articles.first
    assert_equal('me@example.com', article_customer.from)
    assert_equal('customer@example.com', article_customer.to)
    assert_equal('Customer', article_customer.sender.name)
    assert_equal('email', article_customer.type.name)
    article_notification = article_p.ticket.articles[1]
    assert_match(%r{New Ticket add. info}, article_notification.subject)
    assert_no_match(%r{me@example.com}, article_notification.to)
    assert_match(%r{#{agent1.email}}, article_notification.to)
    assert_equal('System', article_notification.sender.name)
    assert_equal('email', article_notification.type.name)

    Setting.set('ticket_trigger_recursive', false)

    email_raw_string = "From: me@example.com
To: customer@example.com
Subject: some new subject

Some Text"

    ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal(true, mail[:'x-zammad-send-auto-response'])
    Scheduler.worker(true)

    tags = ticket_p.tag_list
    assert_equal('open', ticket_p.state.name)
    assert_equal('3 high', ticket_p.priority.name)
    assert(tags.include?('aa'))
    assert(tags.include?('kk'))
    assert(tags.include?('agent-notification'))
    assert_equal(2, article_p.ticket.articles.count)
    article_customer = article_p.ticket.articles[0]
    assert_equal('me@example.com', article_customer.from)
    assert_equal('customer@example.com', article_customer.to)
    assert_equal('Customer', article_customer.sender.name)
    assert_equal('email', article_customer.type.name)
    article_notification = article_p.ticket.articles[1]
    assert_match(%r{New Ticket add. info}, article_notification.subject)
    assert_no_match(%r{me@example.com}, article_notification.to)
    assert_match(%r{#{agent1.email}}, article_notification.to)
    assert_equal('System', article_notification.sender.name)
    assert_equal('email', article_notification.type.name)

    Setting.set('ticket_trigger_recursive', true)

    ticket_p, article_p, _user_p, mail = Channel::EmailParser.new.process({}, email_raw_string)
    assert_equal(true, mail[:'x-zammad-send-auto-response'])
    Scheduler.worker(true)
    tags = ticket_p.tag_list
    assert_equal('open', ticket_p.state.name)
    assert_equal('3 high', ticket_p.priority.name)
    assert(tags.include?('aa'))
    assert(tags.include?('kk'))
    assert(tags.include?('agent-notification'))
    assert(tags.include?('auto-reply'))
    assert_equal(3, article_p.ticket.articles.count)
    article_customer = article_p.ticket.articles[0]
    assert_equal('me@example.com', article_customer.from)
    assert_equal('customer@example.com', article_customer.to)
    assert_equal('Customer', article_customer.sender.name)
    assert_equal('email', article_customer.type.name)
    article_notification = article_p.ticket.articles[1]
    assert_match(%r{New Ticket add. info}, article_notification.subject)
    assert_no_match(%r{me@example.com}, article_notification.to)
    assert_match(%r{#{agent1.email}}, article_notification.to)
    assert_equal('System', article_notification.sender.name)
    assert_equal('email', article_notification.type.name)
    article_auto_reply = article_p.ticket.articles[2]
    assert_match(%r{Thanks for your inquiry}, article_auto_reply.subject)
    assert_match(%r{me@example.com}, article_auto_reply.to)
    assert_equal('System', article_auto_reply.sender.name)
    assert_equal('email', article_auto_reply.type.name)

  end

end
