# encoding: utf-8
require 'browser_test_helper'

class ChatTest < TestCase
  def test_websocket
    return # TODO: temp disable
    message = 'message 1äöüß ' + rand(99_999_999_999_999_999).to_s
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
            :css     => '#chat_toogle',
          },
          {
            :execute => 'wait',
            :value   => 8,
          },
          {
            :where   => :instance1,
            :execute => 'click',
            :css     => '#chat_toogle',
          },
          {
            :execute => 'wait',
            :value   => 4,
          },
          {
            :where   => :instance2,
            :execute => 'click',
            :css     => '#chat_toogle',
          },
          {
            :where   => :instance1,
            :execute => 'click',
            :css     => '#chat_toogle',
          },
          {
            :execute => 'wait',
            :value   => 2,
          },
          {
            :where   => :instance1,
            :execute => 'set',
            :css     => 'input[name="chat_message"]',
            :value   => message,
          },
          {
            :where   => :instance1,
            :execute => 'send_key',
            :css     => 'input[name="chat_message"]',
            :value   => :enter,
          },
          {
            :execute => 'wait',
            :value   => 6,
          },
          {
            :where        => :instance1,
            :execute      => 'match',
            :css          => '#chat_log_container',
            :value        => message,
            :match_result => true,
          },
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => '#chat_log_container',
            :value        => message,
            :match_result => true,
          },
          {
            :where        => :instance1,
            :execute      => 'navigate',
            :to           => browser_url,
          },
          {
            :execute => 'wait',
            :value   => 8,
          },
          {
            :where   => :instance1,
            :execute => 'click',
            :css     => '#chat_toogle',
          },
          {
            :execute => 'wait',
            :value   => 8,
          },
          {
            :where        => :instance1,
            :execute      => 'match',
            :css          => '#chat_log_container',
            :value        => message,
            :match_result => true,
          },
        ],
      },
    ]
    browser_double_test(tests)
  end
end
