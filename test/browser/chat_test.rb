# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class ChatTest < TestCase

  def test_basic
    chat_url = "#{browser_url}/assets/chat/znuny.html?port=#{ENV['WS_PORT']}"
    agent = browser_instance
    login(
      browser:  agent,
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all(
      browser: agent,
    )

    # disable chat
    click(
      browser: agent,
      css:     'a[href="#manage"]',
    )
    click(
      browser: agent,
      css:     '.content.active a[href="#channels/chat"]',
    )
    switch(
      browser: agent,
      css:     '.content.active .js-chatSetting',
      type:    'off',
    )

    # nav bar shuld be gone
    sleep 2
    exists_not(
      browser: agent,
      css:     'a[href="#customer_chat"]',
    )
    sleep 15

    customer = browser_instance
    location(
      browser: customer,
      url:     chat_url,
    )
    sleep 4
    exists_not(
      browser: customer,
      css:     '.zammad-chat',
    )
    match(
      browser: customer,
      css:     '.settings',
      value:   '{"state":"chat_disabled"}',
    )
    click(
      browser: agent,
      css:     'a[href="#manage"]',
    )
    click(
      browser: agent,
      css:     '.content.active a[href="#channels/chat"]',
    )
    switch(
      browser: agent,
      css:     '.content.active .js-chatSetting',
      type:    'on',
    )
    sleep 15 # wait for rerendering
    switch(
      browser: agent,
      css:     '#navigation .js-chatMenuItem .js-switch',
      type:    'off',
    )
    click(
      browser: agent,
      css:     'a[href="#customer_chat"]',
      wait:    2,
    )
    match_not(
      browser: agent,
      css:     '.active.content',
      value:   'disabled',
    )

    reload(
      browser: customer,
    )
    sleep 4
    exists_not(
      browser: customer,
      css:     '.zammad-chat',
    )
    match_not(
      browser: customer,
      css:     '.settings',
      value:   '{"state":"chat_disabled"}',
    )
    match(
      browser: customer,
      css:     '.settings',
      value:   '{"event":"chat_status_customer","data":{"state":"offline"}}',
    )
    click(
      browser: agent,
      css:     'a[href="#customer_chat"]',
    )
    switch(
      browser: agent,
      css:     '#navigation .js-chatMenuItem .js-switch',
      type:    'on',
    )
    reload(
      browser: customer,
    )
    watch_for(
      browser: customer,
      css:     '.zammad-chat',
      timeout: 5,
    )
    match_not(
      browser: customer,
      css:     '.settings',
      value:   '{"state":"chat_disabled"}',
    )
    match_not(
      browser: customer,
      css:     '.settings',
      value:   '{"event":"chat_status_customer","data":{"state":"offline"}}',
    )
    match(
      browser: customer,
      css:     '.settings',
      value:   '"data":{"state":"online"}',
    )

    # init chat
    click(
      browser: customer,
      css:     '.zammad-chat .js-chat-open',
    )
    exists(
      browser: customer,
      css:     '.zammad-chat-is-shown',
    )
    watch_for(
      browser: customer,
      css:     '.zammad-chat',
      value:   '(waiting|warte)',
    )
    watch_for(
      browser: agent,
      css:     '.js-chatMenuItem .counter',
      value:   '1',
    )
    click(
      browser: customer,
      css:     '.zammad-chat .js-chat-toggle .zammad-chat-header-icon',
    )
    watch_for_disappear(
      browser: customer,
      css:     '.zammad-chat',
      value:   '(waiting|warte)',
    )
    watch_for_disappear(
      browser: agent,
      css:     '.js-chatMenuItem .counter',
    )

  end

  def test_basic_usecase1
    chat_url = "#{browser_url}/assets/chat/znuny.html?port=#{ENV['WS_PORT']}"
    agent = browser_instance
    login(
      browser:  agent,
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all(
      browser: agent,
    )
    click(
      browser: agent,
      css:     'a[href="#customer_chat"]',
    )
    agent.find_elements(css: '.active .chat-window .js-disconnect:not(.is-hidden)').each(&:click)
    agent.find_elements(css: '.active .chat-window .js-close').each(&:click)

    customer = browser_instance
    location(
      browser: customer,
      url:     chat_url,
    )
    watch_for(
      browser: customer,
      css:     '.zammad-chat',
      timeout: 5,
    )
    click(
      browser: customer,
      css:     '.js-chat-open',
    )
    exists(
      browser: customer,
      css:     '.zammad-chat-is-shown',
    )
    watch_for(
      browser: customer,
      css:     '.zammad-chat',
      value:   '(waiting|warte)',
    )

    click(
      browser: agent,
      css:     '.active .js-acceptChat',
    )
    sleep 2
    exists_not(
      browser: agent,
      css:     '.active .chat-window .chat-status.is-modified',
    )
    match(
      browser: agent,
      css:     '.active .chat-window .js-body',
      value:   chat_url,
    )
    set(
      browser: agent,
      css:     '.active .chat-window .js-customerChatInput',
      value:   'my name is me',
    )
    click(
      browser: agent,
      css:     '.active .chat-window .js-send',
    )
    watch_for(
      browser: customer,
      css:     '.zammad-chat .zammad-chat-agent-status',
      value:   'online',
    )
    watch_for(
      browser: customer,
      css:     '.zammad-chat',
      value:   'my name is me',
    )
    set(
      browser: customer,
      css:     '.zammad-chat .zammad-chat-input',
      value:   'my name is customer',
    )
    click(
      browser: customer,
      css:     '.zammad-chat .zammad-chat-send',
    )
    watch_for(
      browser: agent,
      css:     '.active .chat-window',
      value:   'my name is customer',
    )
    exists(
      browser: agent,
      css:     '.active .chat-window .chat-status.is-modified',
    )
    click(
      browser: agent,
      css:     '.active .chat-window .js-customerChatInput',
    )
    exists_not(
      browser: agent,
      css:     '.active .chat-window .chat-status.is-modified',
    )
    click(
      browser: customer,
      css:     '.js-chat-toggle .zammad-chat-header-icon',
    )
    watch_for(
      browser: agent,
      css:     '.active .chat-window',
      value:   'closed the conversation',
    )
  end

  def test_basic_usecase2
    chat_url = "#{browser_url}/assets/chat/znuny.html?port=#{ENV['WS_PORT']}"
    agent = browser_instance
    login(
      browser:  agent,
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all(
      browser: agent,
    )
    click(
      browser: agent,
      css:     'a[href="#customer_chat"]',
    )
    agent.find_elements(css: '.active .chat-window .js-disconnect:not(.is-hidden)').each(&:click)
    agent.find_elements(css: '.active .chat-window .js-close').each(&:click)

    customer = browser_instance
    location(
      browser: customer,
      url:     chat_url,
    )
    watch_for(
      browser: customer,
      css:     '.zammad-chat',
      timeout: 5,
    )
    click(
      browser: customer,
      css:     '.js-chat-open',
    )
    exists(
      browser: customer,
      css:     '.zammad-chat-is-shown',
    )
    watch_for(
      browser: customer,
      css:     '.zammad-chat',
      value:   '(waiting|warte)',
    )
    click(
      browser: agent,
      css:     '.active .js-acceptChat',
    )
    sleep 2
    exists_not(
      browser: agent,
      css:     '.active .chat-window .chat-status.is-modified',
    )

    # keep focus outside of chat window to check .chat-status.is-modified later
    click(
      browser: agent,
      css:     '#global-search',
    )
    watch_for(
      browser: customer,
      css:     '.zammad-chat .zammad-chat-agent-status',
      value:   'online',
    )
    set(
      browser: customer,
      css:     '.zammad-chat .zammad-chat-input',
      value:   'my name is customer',
    )
    click(
      browser: customer,
      css:     '.zammad-chat .zammad-chat-send',
    )
    watch_for(
      browser: agent,
      css:     '.active .chat-window',
      value:   'my name is customer',
    )
    exists(
      browser: agent,
      css:     '.active .chat-window .chat-status.is-modified',
    )
    set(
      browser: agent,
      css:     '.active .chat-window .js-customerChatInput',
      value:   'my name is me',
    )
    exists_not(
      browser: agent,
      css:     '.active .chat-window .chat-status.is-modified',
    )
    click(
      browser: agent,
      css:     '.active .chat-window .js-send',
    )
    watch_for(
      browser: customer,
      css:     '.zammad-chat',
      value:   'my name is me',
    )
    click(
      browser: agent,
      css:     '.active .chat-window .js-disconnect:not(.is-hidden)',
    )
    click(
      browser: agent,
      css:     '.active .chat-window .js-close',
    )
    watch_for(
      browser: customer,
      css:     '.zammad-chat .zammad-chat-agent-status',
      value:   'offline',
    )
    watch_for(
      browser: customer,
      css:     '.zammad-chat',
      value:   '(Chat closed by|Chat beendet von)',
    )
    click(
      browser: customer,
      css:     '.zammad-chat .js-chat-toggle .zammad-chat-header-icon',
    )
    watch_for_disappear(
      browser: customer,
      css:     '.zammad-chat-is-open',
    )
    agent.find_elements(css: '.active .chat-window .js-disconnect:not(.is-hidden)').each(&:click)
    agent.find_elements(css: '.active .chat-window .js-close').each(&:click)
    sleep 2
    click(
      browser: customer,
      css:     '.zammad-chat .js-chat-open',
    )
    exists(
      browser: customer,
      css:     '.zammad-chat-is-shown',
    )
    watch_for(
      browser: customer,
      css:     '.zammad-chat',
      value:   '(waiting|warte)',
    )
    click(
      browser: agent,
      css:     '.active .js-acceptChat',
    )
    sleep 2
    exists_not(
      browser: agent,
      css:     '.active .chat-window .chat-status.is-modified',
    )
    exists(
      browser: agent,
      css:     '.active .chat-window .chat-status',
    )
  end

  def test_basic_usecase3
    chat_url = "#{browser_url}/assets/chat/znuny.html?port=#{ENV['WS_PORT']}"
    agent = browser_instance
    login(
      browser:  agent,
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all(
      browser: agent,
    )
    click(
      browser: agent,
      css:     'a[href="#customer_chat"]',
    )
    agent.find_elements(css: '.active .chat-window .js-disconnect:not(.is-hidden)').each(&:click)
    agent.find_elements(css: '.active .chat-window .js-close').each(&:click)

    # set chat preferences
    click(
      browser: agent,
      css:     '.active .js-settings',
    )

    modal_ready(browser: agent)
    set(
      browser: agent,
      css:     '.modal [name="chat::phrase::1"]',
      value:   'Hi Stranger!;My Greeting',
    )
    click(
      browser: agent,
      css:     '.modal .js-submit',
    )
    modal_disappear(browser: agent)

    customer = browser_instance
    location(
      browser: customer,
      url:     chat_url,
    )
    watch_for(
      browser: customer,
      css:     '.zammad-chat',
      timeout: 5,
    )
    click(
      browser: customer,
      css:     '.js-chat-open',
    )
    exists(
      browser: customer,
      css:     '.zammad-chat-is-shown',
    )
    watch_for(
      browser: agent,
      css:     '.active .js-badgeWaitingCustomers',
      value:   '1',
    )
    click(
      browser: agent,
      css:     '.active .js-acceptChat',
    )
    watch_for(
      browser: customer,
      css:     '.zammad-chat',
      value:   'Hi Stranger|My Greeting',
    )
    watch_for(
      browser: customer,
      css:     '.zammad-chat .zammad-chat-agent-status',
      value:   'online',
    )
    match(
      browser: agent,
      css:     '.active .chat-window .js-body',
      value:   chat_url,
    )
    set(
      browser: agent,
      css:     '.active .chat-window .js-customerChatInput',
      value:   'my name is me',
    )
    click(
      browser: agent,
      css:     '.active .chat-window .js-send',
    )
    watch_for(
      browser: customer,
      css:     '.zammad-chat',
      value:   'my name is me',
    )
    set(
      browser: customer,
      css:     '.zammad-chat .zammad-chat-input',
      value:   'my name is customer',
    )
    click(
      browser: customer,
      css:     '.zammad-chat .zammad-chat-send',
    )
    watch_for(
      browser: agent,
      css:     '.active .chat-window',
      value:   'my name is customer',
    )
    click(
      browser: agent,
      css:     '.active .chat-window .js-customerChatInput',
    )
    reload(
      browser: customer,
    )
    exists(
      browser: customer,
      css:     '.zammad-chat',
    )
    watch_for(
      browser: customer,
      css:     '.zammad-chat',
      value:   'Hi Stranger|My Greeting',
    )
    watch_for(
      browser: customer,
      css:     '.zammad-chat',
      value:   'my name is me',
    )
    watch_for(
      browser: customer,
      css:     '.zammad-chat',
      value:   'my name is customer',
    )
    location(
      browser: customer,
      url:     "#{chat_url}#new_hash",
    )
    sleep 2
    match(
      browser: agent,
      css:     '.active .chat-window .js-body',
      value:   "#{chat_url}#new_hash",
    )
    click(
      browser: customer,
      css:     '.zammad-chat .js-chat-toggle .zammad-chat-header-icon',
    )
    watch_for(
      browser: agent,
      css:     '.active .chat-window',
      value:   'closed the conversation',
    )
  end

  def test_open_chat_by_button
    chat_url = "#{browser_url}/assets/chat/znuny_open_by_button.html?port=#{ENV['WS_PORT']}"
    agent = browser_instance
    login(
      browser:  agent,
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all(
      browser: agent,
    )
    click(
      browser: agent,
      css:     'a[href="#customer_chat"]',
    )
    agent.find_elements(css: '.active .chat-window .js-disconnect:not(.is-hidden)').each(&:click)
    agent.find_elements(css: '.active .chat-window .js-close').each(&:click)

    customer = browser_instance
    location(
      browser: customer,
      url:     chat_url,
    )
    watch_for(
      browser: customer,
      css:     '.zammad-chat',
      timeout: 5,
    )
    exists_not(
      browser: customer,
      css:     '.zammad-chat-is-shown',
    )
    exists_not(
      browser: customer,
      css:     '.zammad-chat-is-open',
    )
    click(
      browser: customer,
      css:     '.open-zammad-chat',
    )
    watch_for(
      browser: customer,
      css:     '.zammad-chat-is-shown',
      timeout: 4,
    )
    watch_for(
      browser: customer,
      css:     '.zammad-chat-is-open',
      timeout: 4,
    )
    watch_for(
      browser: customer,
      css:     '.zammad-chat',
      value:   '(waiting|warte)',
    )
    click(
      browser: customer,
      css:     '.zammad-chat-header-icon-close',
    )
    watch_for_disappear(
      browser: customer,
      css:     '.zammad-chat-is-shown',
      timeout: 4,
    )
    watch_for_disappear(
      browser: customer,
      css:     '.zammad-chat-is-open',
      timeout: 4,
    )
  end

  def test_timeouts
    chat_url = "#{browser_url}/assets/chat/znuny.html?port=#{ENV['WS_PORT']}"
    agent = browser_instance
    login(
      browser:  agent,
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all(
      browser: agent,
    )
    click(
      browser: agent,
      css:     'a[href="#customer_chat"]',
    )
    agent.find_elements(css: '.active .chat-window .js-disconnect:not(.is-hidden)').each(&:click)
    agent.find_elements(css: '.active .chat-window .js-close').each(&:click)

    exists(
      browser: agent,
      css:     '#navigation .js-chatMenuItem .js-switch input[checked]'
    )

    # no customer action, hide widget
    customer = browser_instance
    location(
      browser: customer,
      url:     chat_url,
    )
    watch_for(
      browser: customer,
      css:     '.zammad-chat',
      timeout: 5,
    )
    watch_for_disappear(
      browser: customer,
      css:     '.zammad-chat',
      timeout: 95,
    )

    # no agent action, show sorry screen
    reload(
      browser: customer,
    )
    exists(
      browser: customer,
      css:     '.zammad-chat',
    )
    click(
      browser: customer,
      css:     '.js-chat-open',
    )
    watch_for(
      browser: customer,
      css:     '.zammad-chat',
      value:   '(waiting|warte)',
      timeout: 35,
    )
    watch_for(
      browser: customer,
      css:     '.zammad-chat',
      value:   '(takes longer|dauert länger)',
      timeout: 120,
    )

    # check if agent is offline, idle timeout, chat not answered
    exists_not(
      browser: agent,
      css:     '#navigation .js-chatMenuItem .js-switch input[checked]'
    )
    switch(
      browser: agent,
      css:     '#navigation .js-chatMenuItem .js-switch',
      type:    'on',
    )

    # no customer action, show sorry screen
    reload(
      browser: customer,
    )
    exists(
      browser: customer,
      css:     '.zammad-chat',
    )
    click(
      browser: customer,
      css:     '.js-chat-open',
    )
    watch_for(
      browser: agent,
      css:     '.js-chatMenuItem .counter',
      value:   '1',
    )
    click(
      browser: agent,
      css:     '.active .js-acceptChat',
    )
    sleep 2
    set(
      browser: agent,
      css:     '.active .chat-window .js-customerChatInput',
      value:   'agent is asking',
    )
    click(
      browser: agent,
      css:     '.active .chat-window .js-send',
    )
    watch_for(
      browser: customer,
      css:     '.zammad-chat',
      value:   'agent is asking',
    )
    watch_for(
      browser: customer,
      css:     '.zammad-chat',
      value:   '(Since you didn\'t respond|Da Sie in den letzten)',
      timeout: 150,
    )

    agent.find_elements( { css: '.active .chat-window .js-close' } ).each(&:click)
    sleep 2
    click(
      browser: customer,
      css:     '.js-restart',
    )
    sleep 5
    click(
      browser: customer,
      css:     '.js-chat-open',
    )
    exists(
      browser: customer,
      css:     '.zammad-chat-is-shown',
    )
    watch_for(
      browser: customer,
      css:     '.zammad-chat',
      value:   '(waiting|warte)',
    )
    click(
      browser: agent,
      css:     '.active .js-acceptChat',
    )
    sleep 2
    exists(
      browser: agent,
      css:     '.active .chat-window .chat-status',
    )
    set(
      browser: agent,
      css:     '.active .chat-window .js-customerChatInput',
      value:   'my name is me',
    )
    click(
      browser: agent,
      css:     '.active .chat-window .js-send',
    )
    watch_for(
      browser: customer,
      css:     '.zammad-chat .zammad-chat-agent-status',
      value:   'online',
    )
    watch_for(
      browser: customer,
      css:     '.zammad-chat',
      value:   'my name is me',
    )

  end

  def disable_chat
    login(
      browser:  agent,
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all(
      browser: agent,
    )

    # disable chat
    click(
      browser: agent,
      css:     'a[href="#manage"]',
    )
    click(
      browser: agent,
      css:     '.content.active a[href="#channels/chat"]',
    )
    switch(
      browser: agent,
      css:     '.content.active .js-chatSetting',
      type:    'off',
    )
  end

end
