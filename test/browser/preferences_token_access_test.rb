# encoding: utf-8
require 'browser_test_helper'

class PreferencesTokenAccessTest < TestCase

  def test_token_access
    @browser = browser_instance
    login(
      username: 'agent1@example.com',
      password: 'test',
      url: browser_url,
    )
    tasks_close_all()
    click(css: 'a[href="#current_user"]')
    click(css: 'a[href="#profile"]')
    click(css: 'a[href="#profile/token_access"]')

    click(css: '#content .js-create')
    watch_for(
      css: '.modal .modal-title',
      value: 'Add a Personal Access Token'
    )

    set(
      css:   '#content .modal .js-input',
      value: 'Some App#1',
    )
    set(
      css:   '#content .modal .js-datepicker',
      value: '05/15/2022',
    )
    sendkey(value: :tab)
    click(css: '#content .modal input[value="ticket.agent"] ~ .label-text')
    click(css: '#content .modal .js-submit')
    watch_for(
      css: '.modal .modal-title',
      value: 'Your New Personal Access Token'
    )
    click(css: '.modal .js-submit')
    watch_for(
      css: '#content .js-tokenList',
      value: 'Some App#1'
    )
    watch_for(
      css: '#content .js-tokenList',
      value: '05/15/2022'
    )

    click(css: '#content .js-create')
    watch_for(
      css: '.modal .modal-title',
      value: 'Add a Personal Access Token'
    )
    set(
      css:   '#content .modal .js-input',
      value: 'Some App#2',
    )
    click(css: '#content .modal input[value="ticket.agent"] ~ .label-text')
    click(css: '#content .modal .js-submit')

    watch_for(
      css: '.modal .modal-title',
      value: 'Your New Personal Access Token'
    )
    click(css: '.modal .js-submit')
    watch_for(
      css: '#content .js-tokenList',
      value: 'Some App#2'
    )

    click(css: '#content .js-tokenList a')
    watch_for(
      css: '#content .modal .modal-header',
      value: 'confirm',
    )
    click(
      css: '#content .modal .js-submit',
    )
    watch_for_disappear(
      css: '#content .js-tokenList',
      value: 'Some App#2'
    )

  end
end
