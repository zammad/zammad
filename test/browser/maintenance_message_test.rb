# encoding: utf-8
require 'browser_test_helper'

class MaintenanceMessageTest < TestCase
  def test_websocket
    message = 'message 1äöüß ' + rand(99999999999999999).to_s
    tests = [
      {
        :name     => 'start',
        :instance1 => browser_instance,
        :instance2 => browser_instance,
        :instance1_username => 'master@example.com',
        :instance1_password => 'test',
        :instance2_username => 'agent1@example.com',
        :instance2_password => 'test',
        :url      => browser_url,
        :action   => [
          {
            :where   => :instance1,
            :execute => 'check',
            :css     => '#login',
            :result  => false,
          },
          {
            :where   => :instance2,
            :execute => 'check',
            :css     => '#login',
            :result  => false,
          },
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
            :execute => 'wait',
            :value   => 1,
          },
          {
            :where   => :instance1,
            :execute => 'click',
            :css     => 'a[href="#maintenance"]',
          },
          {
            :execute => 'wait',
            :value   => 1,
          },
          {
            :where   => :instance1,
            :execute => 'set',
            :css     => 'input[name="title"]',
            :value   => message,
          },
          {
            :where   => :instance1,
            :execute => 'set',
            :css     => 'textarea[name="message"]',
            :value   => message,
          },
          {
            :where   => :instance1,
            :execute => 'click',
            :css     => 'button[type="submit"]',
          },
          {
            :execute => 'wait',
            :value   => 5,
          },
          {
            :where   => :instance2,
            :execute => 'check',
            :css     => '.modal-header',
            :result  => true,
          },
          {
            :where   => :instance2,
            :execute      => 'match',
            :css          => 'body',
            :value        => message,
            :match_result => true,
          },
          {
            :where   => :instance2,
            :execute => 'click',
            :css     => 'div.modal-backdrop.fade.in',
          },
        ],
      },
      {
        :name     => 'start',
        :action   => [
          {
            :where   => :instance1,
            :execute => 'check',
            :css     => '#login',
            :result  => false,
          },
          {
            :where   => :instance2,
            :execute => 'check',
            :css     => '#login',
            :result  => false,
          },
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
            :execute => 'wait',
            :value   => 1,
          },
          {
            :where   => :instance1,
            :execute => 'click',
            :css     => 'a[href="#maintenance"]',
          },
          {
            :execute => 'wait',
            :value   => 1,
          },
          {
            :where   => :instance1,
            :execute => 'set',
            :css     => 'input[name="title"]',
            :value   => message,
          },
          {
            :where   => :instance1,
            :execute => 'set',
            :css     => 'textarea[name="message"]',
            :value   => message,
          },
          {
            :execute => 'wait',
            :value   => 5,
          },
          {
            :where   => :instance2,
            :execute => 'check',
            :css     => 'div.modal-backdrop.fade.in',
            :result  => false,
          },
          {
            :where   => :instance2,
            :execute      => 'match',
            :css          => 'body',
            :value        => message,
            :match_result => false,
          },
        ],
      },
    ]
    browser_double_test(tests)
  end
end
