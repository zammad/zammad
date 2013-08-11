# encoding: utf-8
require 'browser_test_helper'

class CustomerTicketCreateTest < TestCase
  def test_customer_ticket_create
    tests = [
      {
        :name     => 'customer ticket create',
        :action   => [
          {
            :execute => 'click',
            :css     => 'a[href="#customer_ticket_new"]',
          },
          {
            :execute => 'check',
            :css     => '.ticket-create',
            :result  => true,
          },
          {
            :execute => 'wait',
            :value   => 1,
          },
          {
            :execute => 'select',
            :css     => '.ticket-create select[name="group_id"]',
            :value   => 'Users',
          },
          {
            :execute => 'set',
            :css     => '.ticket-create input[name="subject"]',
            :value   => 'some subject 123äöü',
          },
          {
            :execute => 'set',
            :css     => '.ticket-create textarea[name="body"]',
            :value   => 'some body 123äöü',
          },
          {
            :execute => 'click',
            :css     => '.ticket-create button[type="submit"]',
          },
          {
            :execute => 'wait',
            :value   => 3,
          },
          {
            :execute => 'check',
            :element => :url,
            :result  => '#ticket/zoom/',
          },

          # check ticket
          {
            :execute      => 'match',
            :css          => '.active div.article',
            :value        => 'some body 123äöü',
            :match_result => true,
          },

          # update ticket
          {
            :execute => 'check',
            :css     => '.active textarea[name="body"]',
            :result  => true,
          },
          {
            :execute => 'set',
            :css     => '.active textarea[name="body"]',
            :value   => 'some body 1234 äöüß',
          },
          {
            :execute => 'click',
            :css     => '.active button',
            :type    => 'submit',
          },
          {
            :execute => 'wait',
            :value   => 4,
          },
          {
            :execute      => 'match',
            :css          => 'body',
            :value        => 'some body 1234 äöüß',
            :match_result => true,
          },
        ],
      },
    ]
    browser_signle_test_with_login(tests)
  end
end
