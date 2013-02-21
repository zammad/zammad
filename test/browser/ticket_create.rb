# encoding: utf-8
require 'browser_test_helper'

class TicketCreate < ActiveSupport::TestCase
  test 'ticket create' do
    tests = [
      {
        :name     => 'phone ticket',
        :action   => [
          {
            :execute => 'click',
            :element => :link,
            :href    => '#customer_ticket_new',
          },
          {
            :execute => 'wait',
            :value   => 2,
          },
          {
            :execute => 'check',
            :element => :div,
            :id      => 'form_create',
            :result  => true,
          },
          {
            :execute => 'wait',
            :value   => 2,
          },
          {
            :execute => 'select',
            :element => :select_list,
            :name    => 'group_id',
            :value   => 'Users',
          },
          {
            :execute => 'set',
            :element => :text_field,
            :name    => 'subject',
            :value   => 'some subject 123äöü',
          },
          {
            :execute => 'set',
            :element => :text_field,
            :name    => 'body',
            :value   => 'some body 123äöü',
          },
          {
            :execute => 'click',
            :element => :button,
            :type    => 'submit',
          },
          {
            :execute => 'wait',
            :value   => 5,
          },
          {
            :execute => 'check',
            :element => :form,
            :id      => 'login',
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
            :element      => :div,
            :class        => 'article',
            :value        => 'some body 123äöü',
            :match_result => true,
          },

          # update ticket
          {
            :execute => 'check',
            :element => :text_field,
            :name    => 'body',
            :result  => true,
          },
          {
            :execute => 'set',
            :element => :text_field,
            :name    => 'body',
            :value   => 'some body 1234 äöüß',
          },
          {
            :execute => 'click',
            :element => :button,
            :type    => 'submit',
          },
          {
            :execute => 'wait',
            :value   => 5,
          },
          {
            :execute      => 'match',
            :element      => :body,
            :value        => 'some body 1234 äöüß',
            :match_result => true,
          },
        ],
      },
    ]
    browser_signle_test_with_login(tests)
  end
end
