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
end
