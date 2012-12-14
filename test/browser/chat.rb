# encoding: utf-8
require 'browser_test_helper'
 
class Chat < ActiveSupport::TestCase
  test 'websocket' do
    message = 'message 1äöüß ' + rand(99999999999999999).to_s
    tests = [
      {
        :name     => 'start',
        :instance1 => Watir::Browser.new,
        :instance2 => Watir::Browser.new,
        :instance1_username => 'm@edenhofer.de',
        :instance1_password => 'test',
        :instance2_username => 'm@edenhofer.de',
        :instance2_password => 'test',        
        :url      => 'http://localhost:3000',
        :action   => [
          {
            :where   => :instance1,
            :execute => 'check',
            :element => :form,
            :id      => 'login',
            :result  => false,
          },
          {
            :where   => :instance2,
            :execute => 'check',
            :element => :form,
            :id      => 'login',
            :result  => false,
          },
          
          {
            :where   => :instance1,
            :execute => 'click',
            :element => :a,
            :id      => 'chat_toogle',
          },
          {
            :where   => :instance1,
            :execute => 'set',
            :element => :text_field,
            :name    => 'chat_message',
            :value   => message,
          },
          {
            :where   => :instance1,
            :execute => 'send_key',
            :element => :text_field,
            :name    => 'chat_message',
            :value   => :enter,
          },
          {
            :execute => 'wait',
            :value   => 3,
          },
          {
            :where        => :instance1,
            :execute      => 'match',
            :element      => :div,
            :id           => 'chat_log_container',
            :value        => message,
            :match_result => true,
          },
          {
            :where        => :instance2,
            :execute      => 'match',
            :element      => :div,
            :id           => 'chat_log_container',
            :value        => message,
            :match_result => true,
          },
          {
            :execute => 'wait',
            :value   => 10,
          },
        ],
      },
    ]
    browser_double_test(tests)
  end
end