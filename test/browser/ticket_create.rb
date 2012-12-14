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
            :value   => 3,
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
        ],
      },
    ]
    browser_signle_test_with_login(tests)
  end
end