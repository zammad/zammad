# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'test_helper'

class EmailBuildTest < ActiveSupport::TestCase
  test 'document complete check' do

    html   = '<b>test</b>'
    result = Channel::EmailBuild.html_complete_check(html)

    assert(result.start_with?('<!DOCTYPE'), 'test 1')
    assert(result !~ %r{^.+?<!DOCTYPE}, 'test 1')
    assert(result.include?('<html>'), 'test 1')
    assert(result.include?('font-family'), 'test 1')
    assert(result.include?('<b>test</b>'), 'test 1')

    html   = 'invalid <!DOCTYPE html><html><b>test</b></html>'
    result = Channel::EmailBuild.html_complete_check(html)

    assert(result !~ %r{^<!DOCTYPE}, 'test 2')
    assert(result =~ %r{^.+?<!DOCTYPE}, 'test 2')
    assert(result.include?('<html>'), 'test 2')
    assert(result !~ %r{font-family}, 'test 2')
    assert(result.include?('<b>test</b>'), 'test 2')

    # Issue #1230, missing backslashes
    # 'Test URL: \\storage\project\100242-Inc'
    html = '<b>Test URL</b>: \\\\storage\\project\\100242-Inc'
    result = Channel::EmailBuild.html_complete_check(html)
    assert(result.include?(html), 'backslashes must be kept')

  end

  test 'html email + attachment check' do
    html = <<~MSG_HTML.chomp
      <!DOCTYPE html>
      <html>
        <head>
          <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
        </head>
        <body style="font-family:Geneva,Helvetica,Arial,sans-serif; font-size: 12px;">
          <div>&gt; Welcome!</div><div>&gt;</div><div>&gt; Thank you for installing Zammad. äöüß</div><div>&gt;</div>
        </body>
      </html>
    MSG_HTML
    mail = Channel::EmailBuild.build(
      from:         'sender@example.com',
      to:           'recipient@example.com',
      body:         html,
      content_type: 'text/html',
      attachments:  [
        {
          'Mime-Type' => 'image/png',
          :content    => 'xxx',
          :filename   => 'somename.png'
        }
      ],
    )

    text_should = <<~MSG_TEXT.chomp
      > Welcome!\r
      >\r
      > Thank you for installing Zammad. äöüß\r
      >\r
    MSG_TEXT
    assert_equal(text_should, mail.text_part.body.to_s)

    html_should = <<~MSG_HTML.chomp
      <!DOCTYPE html>\r
      <html>\r
        <head>\r
          <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>\r
        </head>\r
        <body style="font-family:Geneva,Helvetica,Arial,sans-serif; font-size: 12px;">\r
          <div>&gt; Welcome!</div><div>&gt;</div><div>&gt; Thank you for installing Zammad. äöüß</div><div>&gt;</div>\r
        </body>\r
      </html>
    MSG_HTML
    assert_equal(html_should, mail.html_part.body.to_s)

    parser = Channel::EmailParser.new
    data = parser.parse(mail.to_s)

    # check body
    should = '<div>&gt; Welcome!</div><div>&gt;</div><div>&gt; Thank you for installing Zammad. äöüß</div><div>&gt;</div>'
    assert_equal(should, data[:body])
    assert_equal('text/html', data[:content_type])

    # check count of attachments, only 2, because 3 part is text message and is already in body
    assert_equal(2, data[:attachments].length)

    # check attachments
    data[:attachments]&.each do |attachment|
      case attachment[:filename]
      when 'message.html'
        assert_nil(attachment[:preferences]['Content-ID'])
        assert_equal(true, attachment[:preferences]['content-alternative'])
        assert_equal('text/html', attachment[:preferences]['Mime-Type'])
        assert_equal('UTF-8', attachment[:preferences]['Charset'])
      when 'somename.png'
        assert_nil(attachment[:preferences]['Content-ID'])
        assert_nil(attachment[:preferences]['content-alternative'])
        assert_equal('image/png', attachment[:preferences]['Mime-Type'])
        assert_equal('UTF-8', attachment[:preferences]['Charset'])
      else
        assert(false, "invalid attachment, should not be there, #{attachment.inspect}")
      end
    end
  end

  test 'plain email + attachment check' do
    text = <<~MSG_TEXT.chomp
      > Welcome!
      >
      > Thank you for installing Zammad. äöüß
      >
    MSG_TEXT
    mail = Channel::EmailBuild.build(
      from:        'sender@example.com',
      to:          'recipient@example.com',
      body:        text,
      attachments: [
        {
          'Mime-Type' => 'image/png',
          :content    => 'xxx',
          :filename   => 'somename.png'
        }
      ],
    )

    text_should = <<~MSG_TEXT.chomp
      > Welcome!\r
      >\r
      > Thank you for installing Zammad. äöüß\r
      >\r
    MSG_TEXT
    assert_equal(text_should, mail.text_part.body.to_s)
    assert_nil(mail.html_part)
    assert_equal('image/png; filename=somename.png', mail.attachments[0].content_type)

    parser = Channel::EmailParser.new
    data = parser.parse(mail.to_s)

    # check body
    assert_equal(text, data[:body])

    # check count of attachments, 2
    assert_equal(1, data[:attachments].length)

    # check attachments
    data[:attachments]&.each do |attachment|
      if attachment[:filename] == 'somename.png'
        assert_nil(attachment[:preferences]['Content-ID'])
        assert_nil(attachment[:preferences]['content-alternative'])
        assert_equal('image/png', attachment[:preferences]['Mime-Type'])
        assert_equal('UTF-8', attachment[:preferences]['Charset'])
      else
        assert(false, "invalid attachment, should not be there, #{attachment.inspect}")
      end
    end
  end

  test 'plain email + attachment check 2' do
    ticket1 = Ticket.create!(
      title:         'some article helper test1',
      group:         Group.lookup(name: 'Users'),
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(ticket1, 'ticket created')

    # create inbound article #1
    article1 = Ticket::Article.create!(
      ticket_id:     ticket1.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      content_type:  'text/html',
      body:          'some message article helper test1 <div><img style="width: 85.5px; height: 49.5px" src="cid:15.274327094.140938@zammad.example.com">asdasd<img src="cid:15.274327094.140939@zammad.example.com"><br>',
      internal:      false,
      sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
      type:          Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    store1 = Store.add(
      object:        'Ticket::Article',
      o_id:          article1.id,
      data:          'content_file1_normally_should_be_an_ics_calendar_file',
      filename:      'schedule.ics',
      preferences:   {
        'Mime-Type' => 'text/calendar'
      },
      created_by_id: 1,
    )

    text = <<~MSG_TEXT.chomp
      > Welcome!
      >
      > Thank you for installing Zammad. äöüß
      >
    MSG_TEXT
    mail = Channel::EmailBuild.build(
      from:        'sender@example.com',
      to:          'recipient@example.com',
      body:        text,
      attachments: [
        store1
      ],
    )

    text_should = <<~MSG_TEXT.chomp
      > Welcome!\r
      >\r
      > Thank you for installing Zammad. äöüß\r
      >\r
    MSG_TEXT
    assert_equal(text_should, mail.text_part.body.to_s)
    assert_nil(mail.html_part)
    assert_equal('text/calendar; filename=schedule.ics', mail.attachments[0].content_type)

    parser = Channel::EmailParser.new
    data = parser.parse(mail.to_s)

    # check body
    assert_equal(text, data[:body])

    # check count of attachments, 2
    assert_equal(1, data[:attachments].length)

    # check attachments
    data[:attachments]&.each do |attachment|
      if attachment[:filename] == 'schedule.ics'
        assert(attachment[:preferences]['Content-ID'])
        assert_nil(attachment[:preferences]['content-alternative'])
        assert_equal('text/calendar', attachment[:preferences]['Mime-Type'])
        assert_equal('UTF-8', attachment[:preferences]['Charset'])
      else
        assert(false, "invalid attachment, should not be there, #{attachment.inspect}")
      end
    end
  end

  test 'plain email + without attachment check' do
    text = <<~MSG_TEXT.chomp
      > Welcome!
      >
      > Thank you for installing Zammad. äöüß
      >
    MSG_TEXT
    mail = Channel::EmailBuild.build(
      from: 'sender@example.com',
      to:   'recipient@example.com',
      body: text,
    )

    text_should = <<~MSG_TEXT.chomp
      > Welcome!\r
      >\r
      > Thank you for installing Zammad. äöüß\r
      >\r
    MSG_TEXT
    assert_equal(text_should, mail.body.to_s)
    assert_nil(mail.html_part)

    parser = Channel::EmailParser.new
    data = parser.parse(mail.to_s)

    # check body
    assert_equal(text, data[:body])

    # check count of attachments, 0
    assert_equal(0, data[:attachments].length)

  end

  test 'email - html email client fixes' do

    # https://github.com/martini/zammad/issues/165
    html_raw = '<blockquote type="cite">some
text
</blockquote>

123

<blockquote type="cite">some
text
</blockquote>'
    html_with_fixes = Channel::EmailBuild.html_mail_client_fixes(html_raw)
    assert_not_equal(html_with_fixes, html_raw)

    html_should = '<blockquote type="cite" style="border-left: 2px solid blue; margin: 0 0 16px; padding: 8px 12px 8px 12px;">some
text
</blockquote>

123

<blockquote type="cite" style="border-left: 2px solid blue; margin: 0 0 16px; padding: 8px 12px 8px 12px;">some
text
</blockquote>'
    assert_equal(html_should, html_with_fixes)

    html_raw = '<p>some
text
</p>
<p>123</p>'
    html_with_fixes = Channel::EmailBuild.html_mail_client_fixes(html_raw)
    assert_not_equal(html_with_fixes, html_raw)

    html_should = '<p style="margin: 0;">some
text
</p>
<p style="margin: 0;">123</p>'
    assert_equal(html_should, html_with_fixes)

    html_raw = '<p>sometext</p><hr><p>123</p>'
    html_with_fixes = Channel::EmailBuild.html_mail_client_fixes(html_raw)
    assert_not_equal(html_with_fixes, html_raw)

    html_should = '<p style="margin: 0;">sometext</p><hr style="margin-top: 6px; margin-bottom: 6px; border: 0; border-top: 1px solid #dfdfdf;"><p style="margin: 0;">123</p>'
    assert_equal(html_should, html_with_fixes)
  end

  test 'from checks' do

    quoted_in_one_line = Channel::EmailBuild.recipient_line('Somebody @ "Company"', 'some.body@example.com')
    assert_equal('"Somebody @ \"Company\"" <some.body@example.com>', quoted_in_one_line)

    quoted_in_one_line = Channel::EmailBuild.recipient_line('Somebody', 'some.body@example.com')
    assert_equal('Somebody <some.body@example.com>', quoted_in_one_line)

    quoted_in_one_line = Channel::EmailBuild.recipient_line('Somebody | Some Org', 'some.body@example.com')
    assert_equal('"Somebody | Some Org" <some.body@example.com>', quoted_in_one_line)

    quoted_in_one_line = Channel::EmailBuild.recipient_line('Test Master Agent via Support', 'some.body@example.com')
    assert_equal('"Test Master Agent via Support" <some.body@example.com>', quoted_in_one_line)

  end

  # #2362 - Attached text files get prepended on e-mail reply instead of appended
  test 'plain email + text attachment' do
    ticket1 = Ticket.create!(
      title:         'some article text attachment test',
      group:         Group.lookup(name: 'Users'),
      customer_id:   2,
      state:         Ticket::State.lookup(name: 'new'),
      priority:      Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(ticket1, 'ticket created')

    article1 = Ticket::Article.create!(
      ticket_id:     ticket1.id,
      from:          'some_sender@example.com',
      to:            'some_recipient@example.com',
      subject:       'some subject',
      message_id:    'some@id',
      content_type:  'text/html',
      body:          'some message article helper test1 <div><img style="width: 85.5px; height: 49.5px" src="cid:15.274327094.140938@zammad.example.com">asdasd<img src="cid:15.274327094.140939@zammad.example.com"><br>',
      internal:      false,
      sender:        Ticket::Article::Sender.find_by(name: 'Customer'),
      type:          Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )

    text = <<~MSG_TEXT.chomp
      > Welcome!
      >
      > Email Content
    MSG_TEXT

    store1 = Store.add(
      object:        'Ticket::Article',
      o_id:          article1.id,
      data:          'Text Content',
      filename:      'text_file.txt',
      preferences:   {
        'Mime-Type' => 'text/plain'
      },
      created_by_id: 1,
    )

    mail = Channel::EmailBuild.build(
      from:        'sender@example.com',
      to:          'recipient@example.com',
      body:        text,
      attachments: [
        store1
      ],
    )
    File.write('append_test.eml', mail.to_s)

    # Email Content should appear before the Text Content within the raw email
    assert_match(%r{Email Content[\s\S]*Text Content}, mail.to_s)
  end
end
