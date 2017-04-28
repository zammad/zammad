# encoding: utf-8
require 'test_helper'

class TicketXssTest < ActiveSupport::TestCase
  test 'xss via model' do
    ticket = Ticket.create(
      title: 'test 123 <script type="text/javascript">alert("XSS!");</script>',
      group: Group.lookup(name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert(ticket, 'ticket created')

    assert_equal('test 123 <script type="text/javascript">alert("XSS!");</script>', ticket.title, 'ticket.title verify')
    assert_equal('Users', ticket.group.name, 'ticket.group verify')
    assert_equal('new', ticket.state.name, 'ticket.state verify')

    article1 = Ticket::Article.create(
      ticket_id: ticket.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject <script type="text/javascript">alert("XSS!");</script>',
      message_id: 'some@id',
      content_type: 'text/html',
      body: '<script type="text/javascript">alert("XSS!");</script>',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Customer'),
      type: Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal('alert("XSS!");', article1.body, 'article1.body verify - inbound')

    article2 = Ticket::Article.create(
      ticket_id: ticket.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject <script type="text/javascript">alert("XSS!");</script>',
      message_id: 'some@id',
      content_type: 'text/html',
      body: 'please tell me this doesn\'t work: <script type="text/javascript">alert("XSS!");</script>',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Customer'),
      type: Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal('please tell me this doesn\'t work: alert("XSS!");', article2.body, 'article2.body verify - inbound')

    article3 = Ticket::Article.create(
      ticket_id: ticket.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject <script type="text/javascript">alert("XSS!");</script>',
      message_id: 'some@id',
      content_type: 'text/html',
      body: 'please tell me this doesn\'t work: <table>ada<tr></tr></table><div class="adasd" id="123" data-abc="123"></div><div><a href="javascript:someFunction()">LINK</a><a href="http://lalal.de">aa</a><some_not_existing>ABC</some_not_existing>',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Customer'),
      type: Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal("please tell me this doesn't work: <table>ada<tr></tr>
</table><div></div><div>
LINKaa (<a href=\"http://lalal.de\" rel=\"nofollow noreferrer noopener\" target=\"_blank\">http://lalal.de</a>)ABC</div>", article3.body, 'article3.body verify - inbound')

    article4 = Ticket::Article.create(
      ticket_id: ticket.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject <script type="text/javascript">alert("XSS!");</script>',
      message_id: 'some@id',
      content_type: 'text/html',
      body: 'please tell me this doesn\'t work: <video>some video</video><foo>alal</foo>',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Customer'),
      type: Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal("please tell me this doesn't work: <video>some video</video>alal", article4.body, 'article4.body verify - inbound')

    article5 = Ticket::Article.create(
      ticket_id: ticket.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject <script type="text/javascript">alert("XSS!");</script>',
      message_id: 'some@id',
      content_type: 'text/plain',
      body: 'please tell me this doesn\'t work: <table>ada<tr></tr></table><div class="adasd" id="123" data-signature-id="123"></div><div><a href="javascript:someFunction()">LINK</a><a href="http://lalal.de">aa</a><some_not_existing>ABC</some_not_existing>',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Customer'),
      type: Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal('please tell me this doesn\'t work: <table>ada<tr></tr></table><div class="adasd" id="123" data-signature-id="123"></div><div><a href="javascript:someFunction()">LINK</a><a href="http://lalal.de">aa</a><some_not_existing>ABC</some_not_existing>', article5.body, 'article5.body verify - inbound')

    article6 = Ticket::Article.create(
      ticket_id: ticket.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject <script type="text/javascript">alert("XSS!");</script>',
      message_id: 'some@id',
      content_type: 'text/html',
      body: 'some message article helper test1 <div><img style="width: 85.5px; height: 49.5px" src="cid:15.274327094.140938@zammad.example.com">asdasd<img src="cid:15.274327094.140939@zammad.example.com"><br>',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Customer'),
      type: Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal('some message article helper test1 <div>
<img style="width: 85.5px; height: 49.5px;" src="cid:15.274327094.140938@zammad.example.com">asdasd<img src="cid:15.274327094.140939@zammad.example.com"><br>
</div>', article6.body, 'article6.body verify - inbound')

    article7 = Ticket::Article.create(
      ticket_id: ticket.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject <script type="text/javascript">alert("XSS!");</script>',
      message_id: 'some@id',
      content_type: 'text/html',
      body: 'some message article helper test1 <div><img style="width: 85.5px; height: 49.5px" src="api/v1/ticket_attachment/123/123/123">asdasd<img src="api/v1/ticket_attachment/123/123/123"><br>',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Customer'),
      type: Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal('some message article helper test1 <div>
<img style="width: 85.5px; height: 49.5px;" src="api/v1/ticket_attachment/123/123/123">asdasd<img src="api/v1/ticket_attachment/123/123/123"><br>
</div>', article7.body, 'article7.body verify - inbound')

    article8 = Ticket::Article.create(
      ticket_id: ticket.id,
      from: 'some_sender@example.com',
      to: 'some_recipient@example.com',
      subject: 'some subject <script type="text/javascript">alert("XSS!");</script>',
      message_id: 'some@id',
      content_type: 'text/html',
      body: 'some message article helper test1 <a href="#" onclick="some_function();">abc</a> <a href="https://example.com" oNclIck="some_function();">123</a><body>123</body>',
      internal: false,
      sender: Ticket::Article::Sender.find_by(name: 'Customer'),
      type: Ticket::Article::Type.find_by(name: 'email'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal('some message article helper test1 abc (<a href="#">#</a>) 123 (<a href="https://example.com" rel="nofollow noreferrer noopener" target="_blank">https://example.com</a>)123', article8.body, 'article8.body verify - inbound')

  end

  test 'xss via mail' do
    data = 'From: ME Bob <me@example.com>
To: customer@example.com
Subject: some subject
Content-Type: text/html
MIME-Version: 1.0

no HTML <script type="text/javascript">alert(\'XSS\')</script>'

    parser = Channel::EmailParser.new
    ticket, article, user = parser.process({}, data)
    assert_equal('text/html', ticket.articles.first.content_type)
    assert_equal('no HTML alert(\'XSS\')', ticket.articles.first.body)

    data = 'From: ME Bob <me@example.com>
To: customer@example.com
Subject: some subject
Content-Type: text/plain
MIME-Version: 1.0

no HTML <script type="text/javascript">alert(\'XSS\')</script>'

    parser = Channel::EmailParser.new
    ticket, article, user = parser.process({}, data)
    assert_equal('text/plain', ticket.articles.first.content_type)
    assert_equal('no HTML <script type="text/javascript">alert(\'XSS\')</script>', ticket.articles.first.body)

  end
end
