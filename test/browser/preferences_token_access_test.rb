# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class PreferencesTokenAccessTest < TestCase

  def test_token_access
    @browser = browser_instance
    login(
      username: 'agent1@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()
    click(css: 'a[href="#current_user"]')
    click(css: 'a[href="#profile"]')
    click(css: 'a[href="#profile/token_access"]')

    click(css: '.content.active .js-create')

    modal_ready()
    set(
      css:   '.content.active .modal .js-input',
      value: 'Some App#1',
    )
    set(
      css:   '.content.active .modal .js-datepicker',
      value: '05/15/2022',
    )
    sendkey(value: :tab)
    click(css: '.content.active .modal input[value="ticket.agent"] ~ .label-text')
    click(css: '.content.active .modal .js-submit')
    watch_for(
      css:   '.modal .modal-title',
      value: 'Your New Personal Access Token'
    )
    click(css: '.modal .js-submit')
    modal_disappear()

    watch_for(
      css:   '.content.active .js-tokenList',
      value: 'Some App#1'
    )
    watch_for(
      css:   '.content.active .js-tokenList',
      value: '05/15/2022'
    )

    click(css: '.content.active .js-create')

    modal_ready()
    set(
      css:   '.content.active .modal .js-input',
      value: 'Some App#2',
    )
    click(css: '.content.active .modal input[value="ticket.agent"] ~ .label-text')
    click(css: '.content.active .modal .js-submit')

    watch_for(
      css:   '.modal .modal-title',
      value: 'Your New Personal Access Token'
    )
    click(css: '.modal .js-submit')
    modal_disappear()

    watch_for(
      css:   '.content.active .js-tokenList',
      value: 'Some App#2'
    )

    click(css: '.content.active .js-tokenList .js-delete')

    modal_ready()
    watch_for(
      css:   '.content.active .modal .modal-header',
      value: 'confirm',
    )
    click(
      css: '.content.active .modal .js-submit',
    )
    modal_disappear()
    watch_for_disappear(
      css:   '.content.active .js-tokenList',
      value: 'Some App#2'
    )

  end
end
