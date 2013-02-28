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
            :execute => 'wait',
            :value   => 2,
          },
          {
            :execute => 'check',
            :css     => '#form_create',
            :result  => true,
          },
          {
            :execute => 'wait',
            :value   => 2,
          },
          {
            :execute => 'select',
            :css     => '#form_create select[name="group_id"]',
            :value   => 'Users',
          },
          {
            :execute => 'set',
            :css     => '#form_create input[name="subject"]',
            :value   => 'some subject 123äöü',
          },
          {
            :execute => 'set',
            :css     => '#form_create textarea[name="body"]',
            :value   => 'some body 123äöü',
          },
          {
            :execute => 'click',
            :css     => 'button[type="submit"]',
          },
          {
            :execute => 'wait',
            :value   => 3,
          },
          {
            :execute => 'check',
            :css     => '#login',
            :result  => false,
          },
          {
            :execute => 'check',
            :element => :url,
            :result  => '#ticket/zoom/',
          },

          # check ticket
          {
            :execute      => 'match',
            :css          => 'div.article',
            :value        => 'some body 123äöü',
            :match_result => true,
          },

          # update ticket
          {
            :execute => 'check',
            :css     => 'textarea[name="body"]',
            :result  => true,
          },
          {
            :execute => 'set',
            :css     => 'textarea[name="body"]',
            :value   => 'some body 1234 äöüß',
          },
          {
            :execute => 'click',
            :css     => 'button',
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
