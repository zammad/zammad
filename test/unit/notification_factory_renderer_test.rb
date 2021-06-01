# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'test_helper'

class NotificationFactoryRendererTest < ActiveSupport::TestCase

  # RSpec incoming!
  def described_class
    NotificationFactory::Renderer
  end

  group        = Group.new(name: 'Users')
  owner        = User.new(firstname: 'Owner<b>xxx</b>', lastname: 'Agent1<b>yyy</b>')
  current_user = User.new(firstname: 'CurrentUser<b>xxx</b>', lastname: 'Agent2<b>yyy</b>')
  state        = Ticket::State.new(name: 'new')
  ticket       = Ticket.new(
    id:         1,
    title:      '<b>Welcome to Zammad!</b>',
    group:      group,
    owner:      owner,
    state:      state,
    created_by: current_user,
    updated_by: current_user,
    created_at: Time.zone.parse('2016-11-12 12:00:00 UTC'),
    updated_at: Time.zone.parse('2016-11-12 14:00:00 UTC'),
  )
  article_html1 = Ticket::Article.new(
    body:         'test <b>hello</b><br>some new line',
    content_type: 'text/html',
  )
  article_plain1 = Ticket::Article.new(
    body:         "test <b>hello</b>\nsome new line",
    content_type: 'text/plain',
  )
  article_plain2 = Ticket::Article.new(
    body: "test <b>hello</b>\nsome new line",
  )

  test 'replace object attribute' do

    template = "\#{ticket.title}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal(CGI.escapeHTML(ticket.title), result)

    template = "\#{ticket.created_at}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal('11/12/2016 13:00 (Europe/Berlin)', result)

    template = "\#{ticket.created_by.firstname}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal('CurrentUser&lt;b&gt;xxx&lt;/b&gt;', result)

    template = "\#{ticket.updated_at}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal('11/12/2016 15:00 (Europe/Berlin)', result)

    template = "\#{ticket.updated_by.firstname}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal('CurrentUser&lt;b&gt;xxx&lt;/b&gt;', result)

    template = "\#{ticket.owner.firstname}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal('Owner&lt;b&gt;xxx&lt;/b&gt;', result)

    template = "\#{ticket. title}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal(CGI.escapeHTML(ticket.title), result)

    template = "\#{ticket.\n title}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal(CGI.escapeHTML(ticket.title), result)

    template = "\#{ticket.\t title}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal(CGI.escapeHTML(ticket.title), result)

    template = "\#{ticket.\t\n title\t}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal(CGI.escapeHTML(ticket.title), result)

    template = "\#{ticket.\" title\t}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal(CGI.escapeHTML(ticket.title), result)

    template = "\#{<a href=\"/test123\">ticket.\" title</a>}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal(CGI.escapeHTML(ticket.title), result)

    template = "some test<br>\#{article.body}"
    result = described_class.new(
      objects:  {
        article: article_html1,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal('some test<br>&gt; test hello<br>&gt; some new line<br>', result)

    result = described_class.new(
      objects:  {
        article: article_plain1,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal('some test<br>&gt; test &lt;b&gt;hello&lt;/b&gt;<br>&gt; some new line<br>', result)

    result = described_class.new(
      objects:  {
        article: article_plain2,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal('some test<br>&gt; test &lt;b&gt;hello&lt;/b&gt;<br>&gt; some new line<br>', result)

  end

  test 'config' do

    setting = 'fqdn'
    template = "\#{config.#{setting}}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal(Setting.get(setting), result)

    setting1 = 'fqdn'
    setting2 = 'product_name'
    template = "some \#{config.#{setting1}} and \#{config.#{setting2}}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal("some #{Setting.get(setting1)} and #{Setting.get(setting2)}", result)

    setting1 = 'fqdn'
    setting2 = 'product_name'
    template = "some \#{ config.#{setting1}} and \#{\tconfig.#{setting2}}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal("some #{Setting.get(setting1)} and #{Setting.get(setting2)}", result)
  end

  test 'translation' do

    #template = "<%= t 'new' %>"
    template = "\#{t('new')}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'de-de',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal('neu', result)

    template = "some text \#{t('new')} and \#{t('open')}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'de-de',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal('some text neu and offen', result)

    template = "some text \#{t('new') } and \#{ t('open')}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'de-de',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal('some text neu and offen', result)

    template = "some text \#{\nt('new') } and \#{ t('open')\t}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'de-de',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal('some text neu and offen', result)

  end

  test 'chained function calls' do

    template = "\#{t(ticket.state.name)}"

    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'de-de',
      timezone: 'Europe/Berlin',
      template: template,
    ).render

    assert_equal('neu', result)
  end

  test 'not existing object and attribute' do

    template = "\#{}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal(CGI.escapeHTML('#{no such object}'), result)

    template = "\#{notexsiting.notexsiting}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal(CGI.escapeHTML('#{notexsiting / no such object}'), result)

    template = "\#{ticket.notexsiting}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal(CGI.escapeHTML('#{ticket.notexsiting / no such method}'), result)

    template = "\#{ticket.}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal(CGI.escapeHTML('#{ticket. / no such method}'), result)

    template = "\#{ticket.title.notexsiting}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal(CGI.escapeHTML('#{ticket.title.notexsiting / no such method}'), result)

    template = "\#{ticket.notexsiting.notexsiting}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal(CGI.escapeHTML('#{ticket.notexsiting / no such method}'), result)

    template = "\#{notexsiting}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal(CGI.escapeHTML('#{notexsiting / no such object}'), result)

    template = "\#{notexsiting.}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal(CGI.escapeHTML('#{notexsiting / no such object}'), result)

    template = "\#{string}"
    result = described_class.new(
      objects:  {
        string: 'some string',
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal(CGI.escapeHTML('some string'), result)

    template = "\#{fixum}"
    result = described_class.new(
      objects:  {
        fixum: 123,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal(CGI.escapeHTML('123'), result)

    template = "\#{float}"
    result = described_class.new(
      objects:  {
        float: 123.99,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal(CGI.escapeHTML('123.99'), result)

  end

  test 'data key validation' do

    template = "\#{ticket.title `echo 1`}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal(CGI.escapeHTML('#{ticket.title`echo1` / not allowed}'), result)

    template = "\#{ticket.destroy}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal(CGI.escapeHTML('#{ticket.destroy / not allowed}'), result)

    template = "\#{ticket.save}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal(CGI.escapeHTML('#{ticket.save / not allowed}'), result)

    template = "\#{ticket.update}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal(CGI.escapeHTML('#{ticket.update / not allowed}'), result)

    template = "\#{ticket.create}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal(CGI.escapeHTML('#{ticket.create / not allowed}'), result)

    template = "\#{ticket.delete}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal(CGI.escapeHTML('#{ticket.delete / not allowed}'), result)

    template = "\#{ticket.remove}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal(CGI.escapeHTML('#{ticket.remove / not allowed}'), result)

    template = "\#{ticket.drop}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal(CGI.escapeHTML('#{ticket.drop / not allowed}'), result)

    template = "\#{ticket.create}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal(CGI.escapeHTML('#{ticket.create / not allowed}'), result)

    template = "\#{ticket.new}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal(CGI.escapeHTML('#{ticket.new / not allowed}'), result)

    template = "\#{ticket.update_att}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal(CGI.escapeHTML('#{ticket.update_att / not allowed}'), result)

    template = "\#{ticket.all}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal(CGI.escapeHTML('#{ticket.all / not allowed}'), result)

    template = "\#{ticket.find}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal(CGI.escapeHTML('#{ticket.find / not allowed}'), result)

    template = "\#{ticket.where}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal(CGI.escapeHTML('#{ticket.where / not allowed}'), result)

    template = "\#{ticket. destroy}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal(CGI.escapeHTML('#{ticket.destroy / not allowed}'), result)

    template = "\#{ticket.\n destroy}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal(CGI.escapeHTML("\#{ticket.destroy / not allowed}"), result)

    template = "\#{ticket.\t destroy}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal(CGI.escapeHTML("\#{ticket.destroy / not allowed}"), result)

    template = "\#{ticket.\r destroy}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal(CGI.escapeHTML("\#{ticket.destroy / not allowed}"), result)

  end

  test 'methods with single Integer parameter' do

    template = "\#{ticket.title.first(3)}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal(CGI.escapeHTML('<b>'), result)

    template = "\#{ticket.title.last(4)}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal(CGI.escapeHTML('</b>'), result)

    template = "\#{ticket.title.slice(3, 4)}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal(CGI.escapeHTML("\#{ticket.title.slice(3,4) / invalid parameter: 3,4}"), result)

    template = "\#{ticket.title.first('some invalid parameter')}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal("\#{ticket.title.first(someinvalidparameter) / invalid parameter: someinvalidparameter}", result)

    template = "\#{ticket.title.chomp(`cat /etc/passwd`)}"
    result = described_class.new(
      objects:  {
        ticket: ticket,
      },
      locale:   'en-us',
      timezone: 'Europe/Berlin',
      template: template,
    ).render
    assert_equal("\#{ticket.title.chomp(`cat/etc/passwd`) / not allowed}", result)
  end
end
