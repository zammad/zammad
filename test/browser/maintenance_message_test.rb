# encoding: utf-8
require 'browser_test_helper'

class MaintenanceMessageTest < TestCase
  def test_websocket
    string       = rand(99999999999999999).to_s
    title_html   = "test <b>#{string}</b>"
    title_text   = "test <b>#{string}<\/b>"
    message_html = "message <b>1äöüß</b> #{string}\n\n\nhttp://zammad.org"
    message_text = "message <b>1äöüß<\/b> #{string}\n\nhttp:\/\/zammad.org"
    tests        = [
      {
        :name     => 'check #1',
        :instance1 => browser_instance,
        :instance2 => browser_instance,
        :instance1_username => 'master@example.com',
        :instance1_password => 'test',
        :instance2_username => 'agent1@example.com',
        :instance2_password => 'test',
        :url      => browser_url,
        :action   => [
          {
            :execute => 'wait',
            :value   => 1,
          },
          {
            :where   => :instance1,
            :execute => 'click',
            :css     => 'a[href="#manage"]',
          },
          {
            :where   => :instance1,
            :execute => 'click',
            :css     => 'a[href="#system/maintenance"]',
          },
          {
            :where   => :instance1,
            :execute => 'set',
            :css     => '#content input[name="head"]',
            :value   => title_html,
          },
          {
            :where   => :instance1,
            :execute => 'set',
            :css     => '#content textarea[name="message"]',
            :value   => message_html,
          },
          {
            :where   => :instance1,
            :execute => 'click',
            :css     => '#content button[type="submit"]',
          },
          {
            :execute => 'wait',
            :value   => 5,
          },
          {
            :where   => :instance2,
            :execute => 'watch_for',
            :area    => '.modal',
            :value   => title_text,
          },
          {
            :where   => :instance2,
            :execute => 'watch_for',
            :area    => '.modal',
            :value   => message_text,
          },
          {
            :where        => :instance1,
            :execute      => 'match',
            :css          => 'body',
            :value        => message_text,
            :match_result => false,
          },
          {
            :where   => :instance2,
            :execute => 'click',
            :css     => 'div.modal-header .close',
          },
          {
            :execute => 'wait',
            :value   => 2,
          },
        ],
      },
      {
        :name     => 'check #2',
        :action   => [
          {
            :where   => :instance1,
            :execute => 'click',
            :css     => 'a[href="#manage"]',
          },
          {
            :where   => :instance1,
            :execute => 'click',
            :css     => 'a[href="#system/maintenance"]',
          },
          {
            :where   => :instance1,
            :execute => 'set',
            :css     => '#content input[name="head"]',
            :value   => title_html + ' #2',
          },
          {
            :where   => :instance1,
            :execute => 'set',
            :css     => '#content textarea[name="message"]',
            :value   => message_html + ' #2',
          },
          {
            :where   => :instance1,
            :execute => 'click',
            :css     => '#content button[type="submit"]',
          },
          {
            :where   => :instance2,
            :execute => 'watch_for',
            :area    => '.modal',
            :value   => title_text,
          },
          {
            :where   => :instance2,
            :execute => 'watch_for',
            :area    => '.modal',
            :value   => message_text + ' #2',
          },
          {
            :where        => :instance1,
            :execute      => 'match',
            :css          => 'body',
            :value        => message_text + ' #2',
            :match_result => false,
          },
          {
            :where    => :instance2,
            :execute  => 'click',
            :css      => 'div.modal-header .close',
          },
          {
            :execute => 'wait',
            :value   => 2,
          },
        ],
      },
      {
        :name     => 'check #3',
        :action   => [
          {
            :where   => :instance1,
            :execute => 'click',
            :css     => 'a[href="#manage"]',
          },
          {
            :where   => :instance1,
            :execute => 'click',
            :css     => 'a[href="#system/maintenance"]',
          },
          {
            :where   => :instance1,
            :execute => 'set',
            :css     => '#content input[name="head"]',
            :value   => title_html + ' #3' ,
          },
          {
            :where   => :instance1,
            :execute => 'set',
            :css     => '#content textarea[name="message"]',
            :value   => message_html + ' #3',
          },
          {
            :where   => :instance1,
            :execute => 'setCheck',
            :css     => '#content input[name="reload"][value="1"]',
          },
          {
            :where   => :instance1,
            :execute => 'click',
            :css     => '#content button[type="submit"]',
          },
          {
            :execute => 'wait',
            :value   => 5,
          },
          {
            :where   => :instance1,
            :execute => 'check',
            :css     => 'div.modal-backdrop.fade.in',
            :result  => false,
          },
          {
            :where   => :instance2,
            :execute => 'watch_for',
            :area    => '.modal',
            :value   => title_text,
          },
          {
            :where   => :instance2,
            :execute => 'watch_for',
            :area    => '.modal',
            :value   => message_text + ' #3',
          },
          {
            :where        => :instance1,
            :execute      => 'match',
            :css          => 'body',
            :value        => message_text + ' #3',
            :match_result => false,
          },
          {
            :where   => :instance2,
            :execute => 'watch_for',
            :area    => '.modal',
            :value   => 'Reload application',
          },
        ],
      },
    ]
    browser_double_test(tests)
  end
end