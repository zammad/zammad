# encoding: utf-8
require 'test_helper'

class NotificationFactoryRendererTest < ActiveSupport::TestCase

  # TODO: should be mocked somehow
  Translation.load('de-de')

  # RSpec incoming!
  def described_class
    NotificationFactory::Renderer
  end

  Group  = Struct.new(:name)
  State  = Struct.new(:name)
  User   = Struct.new(:firstname, :lastname, :longname, :fullname)
  Ticket = Struct.new(:id, :title, :group, :owner, :state)

  group        = Group.new('Users')
  state        = State.new('new')
  owner        = User.new('Notification<b>xxx</b>', 'Agent1<b>yyy</b>', 'Notification<b>xxx</b> Agent1<b>yyy</b>', 'Notification<b>xxx</b> Agent1<b>yyy</b> (Zammad)')
  current_user = User.new('CurrentUser<b>xxx</b>', 'Agent2<b>yyy</b>', 'CurrentUser<b>xxx</b> Agent2<b>yyy</b>', 'CurrentUser<b>xxx</b> Agent2<b>yyy</b> (Zammad)')
  recipient    = User.new('Recipient<b>xxx</b>', 'Customer1<b>yyy</b>', 'Recipient<b>xxx</b> Customer1<b>yyy</b>', 'Recipient<b>xxx</b> Customer1<b>yyy</b> (Zammad)')
  ticket       = Ticket.new(1, '<b>Welcome to Zammad!</b>', group, owner, state)

  test 'replace object attribute' do

    template = "<%= d 'ticket.title' %>"
    result = described_class.new(
      {
        ticket: ticket,
      },
      'en-us',
      template,
    ).render
    assert_equal(CGI.escapeHTML(ticket.title), result)

    template = "<%= d 'ticket. title' %>"
    result = described_class.new(
      {
        ticket: ticket,
      },
      'en-us',
      template,
    ).render
    assert_equal(CGI.escapeHTML(ticket.title), result)

    template = "<%= d 'ticket.\n title' %>"
    result = described_class.new(
      {
        ticket: ticket,
      },
      'en-us',
      template,
    ).render
    assert_equal(CGI.escapeHTML(ticket.title), result)

    template = "<%= d 'ticket.\t title' %>"
    result = described_class.new(
      {
        ticket: ticket,
      },
      'en-us',
      template,
    ).render
    assert_equal(CGI.escapeHTML(ticket.title), result)

    template = "<%= d 'ticket.\t\n title\t' %>"
    result = described_class.new(
      {
        ticket: ticket,
      },
      'en-us',
      template,
    ).render
    assert_equal(CGI.escapeHTML(ticket.title), result)

  end

  test 'config' do

    setting  = 'fqdn'
    template = "<%= c '#{setting}' %>"

    result = described_class.new(
      {
        ticket: ticket,
      },
      'en-us',
      template,
    ).render

    assert_equal(Setting.get(setting), result)

    setting1 = 'fqdn'
    setting2 = 'product_name'
    template = "some <%= c '#{setting1}' %> and <%= c '#{setting2}' %>"

    result = described_class.new(
      {
        ticket: ticket,
      },
      'en-us',
      template,
    ).render

    assert_equal("some #{Setting.get(setting1)} and #{Setting.get(setting2)}", result)
  end

  test 'translation' do

    template = "<%= t 'new' %>"

    result = described_class.new(
      {
        ticket: ticket,
      },
      'de-de',
      template,
    ).render

    assert_equal('neu', result)

    template = "some text <%= t 'new' %> and <%= t 'open' %>"

    result = described_class.new(
      {
        ticket: ticket,
      },
      'de-de',
      template,
    ).render

    assert_equal('some text neu and offen', result)

  end

  test 'chained function calls' do

    template = "<%= t d 'ticket.state.name' %>"

    result = described_class.new(
      {
        ticket: ticket,
      },
      'de-de',
      template,
    ).render

    assert_equal('neu', result)
  end

  test 'not existing object and attribute' do

    template = "<%= d '' %>"
    result = described_class.new(
      {
        ticket: ticket,
      },
      'en-us',
      template,
    ).render
    assert_equal(CGI.escapeHTML('#{no such object}'), result)

    template = "<%= d 'notexsiting.notexsiting' %>"
    result = described_class.new(
      {
        ticket: ticket,
      },
      'en-us',
      template,
    ).render
    assert_equal(CGI.escapeHTML('#{notexsiting / no such object}'), result)

    template = "<%= d 'ticket.notexsiting' %>"
    result = described_class.new(
      {
        ticket: ticket,
      },
      'en-us',
      template,
    ).render
    assert_equal(CGI.escapeHTML('#{ticket.notexsiting / no such method}'), result)

    template = "<%= d 'ticket.' %>"
    result = described_class.new(
      {
        ticket: ticket,
      },
      'en-us',
      template,
    ).render
    assert_equal(CGI.escapeHTML('#{ticket. / no such method}'), result)

    template = "<%= d 'ticket.title.notexsiting' %>"
    result = described_class.new(
      {
        ticket: ticket,
      },
      'en-us',
      template,
    ).render
    assert_equal(CGI.escapeHTML('#{ticket.title.notexsiting / no such method}'), result)

    template = "<%= d 'ticket.notexsiting.notexsiting' %>"
    result = described_class.new(
      {
        ticket: ticket,
      },
      'en-us',
      template,
    ).render
    assert_equal(CGI.escapeHTML('#{ticket.notexsiting / no such method}'), result)

    template = "<%= d 'notexsiting' %>"
    result = described_class.new(
      {
        ticket: ticket,
      },
      'en-us',
      template,
    ).render
    assert_equal(CGI.escapeHTML('#{notexsiting / no such object}'), result)

    template = "<%= d 'notexsiting.' %>"
    result = described_class.new(
      {
        ticket: ticket,
      },
      'en-us',
      template,
    ).render
    assert_equal(CGI.escapeHTML('#{notexsiting / no such object}'), result)

    template = "<%= d 'string' %>"
    result = described_class.new(
      {
        string: 'some string',
      },
      'en-us',
      template,
    ).render
    assert_equal(CGI.escapeHTML('some string'), result)

    template = "<%= d 'fixum' %>"
    result = described_class.new(
      {
        fixum: 123,
      },
      'en-us',
      template,
    ).render
    assert_equal(CGI.escapeHTML('123'), result)

    template = "<%= d 'float' %>"
    result = described_class.new(
      {
        float: 123.99,
      },
      'en-us',
      template,
    ).render
    assert_equal(CGI.escapeHTML('123.99'), result)

  end

  test 'data key validation' do

    template = "<%= d 'ticket.title `echo 1`' %>"
    result = described_class.new(
      {
        ticket: ticket,
      },
      'en-us',
      template,
    ).render
    assert_equal(CGI.escapeHTML('#{ticket.title `echo 1` / not allowed}'), result)

    template = "<%= d 'ticket.destroy' %>"
    result = described_class.new(
      {
        ticket: ticket,
      },
      'en-us',
      template,
    ).render
    assert_equal(CGI.escapeHTML('#{ticket.destroy / not allowed}'), result)

    template = "<%= d 'ticket.save' %>"
    result = described_class.new(
      {
        ticket: ticket,
      },
      'en-us',
      template,
    ).render
    assert_equal(CGI.escapeHTML('#{ticket.save / not allowed}'), result)

    template = "<%= d 'ticket.update' %>"
    result = described_class.new(
      {
        ticket: ticket,
      },
      'en-us',
      template,
    ).render
    assert_equal(CGI.escapeHTML('#{ticket.update / not allowed}'), result)

    template = "<%= d 'ticket.delete' %>"
    result = described_class.new(
      {
        ticket: ticket,
      },
      'en-us',
      template,
    ).render
    assert_equal(CGI.escapeHTML('#{ticket.delete / not allowed}'), result)

    template = "<%= d 'ticket.remove' %>"
    result = described_class.new(
      {
        ticket: ticket,
      },
      'en-us',
      template,
    ).render
    assert_equal(CGI.escapeHTML('#{ticket.remove / not allowed}'), result)

    template = "<%= d 'ticket.drop' %>"
    result = described_class.new(
      {
        ticket: ticket,
      },
      'en-us',
      template,
    ).render
    assert_equal(CGI.escapeHTML('#{ticket.drop / not allowed}'), result)

    template = "<%= d 'ticket.create' %>"
    result = described_class.new(
      {
        ticket: ticket,
      },
      'en-us',
      template,
    ).render
    assert_equal(CGI.escapeHTML('#{ticket.create / not allowed}'), result)

    template = "<%= d 'ticket.new' %>"
    result = described_class.new(
      {
        ticket: ticket,
      },
      'en-us',
      template,
    ).render
    assert_equal(CGI.escapeHTML('#{ticket.new / not allowed}'), result)

    template = "<%= d 'ticket.update_att' %>"
    result = described_class.new(
      {
        ticket: ticket,
      },
      'en-us',
      template,
    ).render
    assert_equal(CGI.escapeHTML('#{ticket.update_att / not allowed}'), result)

    template = "<%= d 'ticket.all' %>"
    result = described_class.new(
      {
        ticket: ticket,
      },
      'en-us',
      template,
    ).render
    assert_equal(CGI.escapeHTML('#{ticket.all / not allowed}'), result)

    template = "<%= d 'ticket.find' %>"
    result = described_class.new(
      {
        ticket: ticket,
      },
      'en-us',
      template,
    ).render
    assert_equal(CGI.escapeHTML('#{ticket.find / not allowed}'), result)

    template = "<%= d 'ticket.where' %>"
    result = described_class.new(
      {
        ticket: ticket,
      },
      'en-us',
      template,
    ).render
    assert_equal(CGI.escapeHTML('#{ticket.where / not allowed}'), result)

    template = "<%= d 'ticket. destroy' %>"
    result = described_class.new(
      {
        ticket: ticket,
      },
      'en-us',
      template,
    ).render
    assert_equal(CGI.escapeHTML('#{ticket. destroy / not allowed}'), result)

    template = "<%= d 'ticket.\n destroy' %>"
    result = described_class.new(
      {
        ticket: ticket,
      },
      'en-us',
      template,
    ).render
    assert_equal(CGI.escapeHTML("\#{ticket.\n destroy / not allowed}"), result)

    template = "<%= d 'ticket.\t destroy' %>"
    result = described_class.new(
      {
        ticket: ticket,
      },
      'en-us',
      template,
    ).render
    assert_equal(CGI.escapeHTML("\#{ticket.\t destroy / not allowed}"), result)

    template = "<%= d 'ticket.\r destroy' %>"
    result = described_class.new(
      {
        ticket: ticket,
      },
      'en-us',
      template,
    ).render
    assert_equal(CGI.escapeHTML("\#{ticket.\r destroy / not allowed}"), result)

  end

end
