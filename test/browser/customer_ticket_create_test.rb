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
            :css     => 'a[href="#new"]',
          },
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
            :css     => '.newTicket',
            :result  => true,
          },
          {
            :execute => 'select',
            :css     => '.newTicket select[name="group_id"]',
            :value   => 'Users',
          },
          {
            :execute => 'set',
            :css     => '.newTicket input[name="title"]',
            :value   => 'some subject 123äöü',
          },
          {
            :execute => 'set',
            :css     => '.newTicket [data-name="body"]',
            :value   => 'some body 123äöü',
          },
          {
            :execute => 'click',
            :css     => '.newTicket button.submit',
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
            :css          => '.active div.ticket-article',
            :value        => 'some body 123äöü',
            :match_result => true,
          },

          # update ticket
          {
            :execute => 'check',
            :css     => '.active [data-name="body"]',
            :result  => true,
          },
          {
            :execute => 'set',
            :css     => '.active [data-name="body"]',
            :value   => 'some body 1234 äöüß',
          },
          {
            :execute => 'click',
            :css     => '.active button.js-submit',
            :type    => 'submit',
          },
          {
            :execute  => 'watch_for',
            :area     => 'body',
            :value    => 'some body 1234 äöüß',
          },
        ],
      },
    ]
    browser_signle_test_with_login(tests)
  end
end
