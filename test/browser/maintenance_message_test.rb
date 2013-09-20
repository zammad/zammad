# encoding: utf-8
require 'browser_test_helper'

class MaintenanceMessageTest < TestCase
  def test_websocket
    message = 'message 1äöüß ' + rand(99999999999999999).to_s
    tests = [
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
            :css     => 'a[href="#admin"]',
          },
          {
            :where   => :instance1,
            :execute => 'click',
            :css     => 'a[href="#maintenance"]',
          },
          {
            :where   => :instance1,
            :execute => 'set',
            :css     => '#content input[name="title"]',
            :value   => message,
          },
          {
            :where   => :instance1,
            :execute => 'set',
            :css     => '#content textarea[name="message"]',
            :value   => message,
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
            :where        => :instance1,
            :execute      => 'match',
            :css          => 'body',
            :value        => message,
            :match_result => false,
          },
          {
            :where    => :instance2,
            :execute  => 'check',
            :css      => '.modal-header',
            :result   => true,
          },
          {
            :where    => :instance2,
            :execute  => 'watch_for',
            :area     => 'body',
            :value    => message,
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
            :css     => 'a[href="#admin"]',
          },
          {
            :where   => :instance1,
            :execute => 'click',
            :css     => 'a[href="#maintenance"]',
          },
          {
            :where   => :instance1,
            :execute => 'set',
            :css     => '#content input[name="title"]',
            :value   => message + ' #2',
          },
          {
            :where   => :instance1,
            :execute => 'set',
            :css     => '#content textarea[name="message"]',
            :value   => message + ' #2',
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
            :where        => :instance1,
            :execute      => 'match',
            :css          => 'body',
            :value        => message + ' #2',
            :match_result => false,
          },
          {
            :where   => :instance1,
            :execute => 'check',
            :css     => 'div.modal-backdrop.fade.in',
            :result  => false,
          },
          {
            :where    => :instance2,
            :execute  => 'watch_for',
            :area     => 'body',
            :value    => message + ' #2',
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
            :css     => 'a[href="#admin"]',
          },
          {
            :where   => :instance1,
            :execute => 'click',
            :css     => 'a[href="#maintenance"]',
          },
          {
            :where   => :instance1,
            :execute => 'set',
            :css     => '#content input[name="title"]',
            :value   => message + ' #3' ,
          },
          {
            :where   => :instance1,
            :execute => 'set',
            :css     => '#content textarea[name="message"]',
            :value   => message + ' #3',
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
            :where        => :instance1,
            :execute      => 'match',
            :css          => 'body',
            :value        => message + ' #3',
            :match_result => false,
          },
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => 'body',
            :value        => message + ' #3',
            :match_result => true,
          },
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => 'body',
            :value        => 'Reload application',
            :match_result => true,
          },
        ],
      },
    ]
    browser_double_test(tests)
  end
end
