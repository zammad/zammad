# encoding: utf-8
require 'browser_test_helper'

class AgentTicketActionLevel1Test < TestCase
  def test_agent_ticket_create
    tests = [
      {
        :name     => 'agent ticket create 1',
        :action   => [
          {
            :execute => 'close_all_tasks',
          },
          {
            :execute => 'click',
            :css     => 'a[href="#new"]',
          },
          {
            :execute => 'click',
            :css     => 'a[href="#ticket_create/call_inbound"]',
          },
          {
            :execute => 'wait',
            :value   => 5,
          },
          {
            :execute => 'check',
            :css     => '.active .ticket_create',
            :result  => true,
          },
          {
            :execute => 'wait',
            :value   => 1,
          },
          {
            :execute => 'set',
            :css     => '.active .ticket_create input[name="customer_id_autocompletion"]',
            :value   => 'ma',
          },
          {
            :execute => 'wait',
            :value   => 4,
          },
          {
            :execute => 'sendkey',
            :css     => '.active .ticket_create input[name="customer_id_autocompletion"]',
            :value   => :arrow_down,
          },
          {
            :execute => 'sendkey',
            :css     => '.active .ticket_create input[name="customer_id_autocompletion"]',
            :value   => :tab,
          },
          {
            :execute => 'select',
            :css     => '.active .ticket_create select[name="group_id"]',
            :value   => 'Users',
          },
          {
            :execute => 'set',
            :css     => '.active .ticket_create input[name="subject"]',
            :value   => 'some subject 123äöü',
          },
          {
            :execute => 'set',
            :css     => '.active .ticket_create textarea[name="body"]',
            :value   => 'some body 123äöü',
          },
          {
            :execute => 'click',
            :css     => '.active .form-actions button[type="submit"]',
          },
          {
            :execute => 'wait',
            :value   => 5,
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
            :css          => '.active div.article',
            :value        => 'some body 123äöü',
            :match_result => true,
          },

          # remember old ticket where we want to merge to
          {
            :execute      => 'match',
            :css          => '.active .ticket-zoom small',
            :value        => '^(.*)$',
            :no_quote     => true,
            :match_result => true,
          },

          # update ticket
          {
            :execute => 'select',
            :css     => '.active select[name="ticket_article_type_id"]',
            :value   => 'note',
          },
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
          {
            :execute => 'click',
            :css     => '#task [data-type="close"]',
          },
        ],
      },

      {
        :name     => 'agent ticket create 2',
        :action   => [
          {
            :execute => 'click',
            :css     => 'a[href="#new"]',
          },
          {
            :execute => 'click',
            :css     => 'a[href="#ticket_create/call_inbound"]',
          },
          {
            :execute => 'wait',
            :value   => 5,
          },
          {
            :execute => 'check',
            :css     => '.active .ticket_create',
            :result  => true,
          },
          {
            :execute => 'wait',
            :value   => 1,
          },
          {
            :execute => 'set',
            :css     => '.active .ticket_create input[name="customer_id_autocompletion"]',
            :value   => 'ma',
          },
          {
            :execute => 'wait',
            :value   => 4,
          },
          {
            :execute => 'sendkey',
            :css     => '.active .ticket_create input[name="customer_id_autocompletion"]',
            :value   => :arrow_down,
          },
          {
            :execute => 'sendkey',
            :css     => '.active .ticket_create input[name="customer_id_autocompletion"]',
            :value   => :tab,
          },
          {
            :execute => 'select',
            :css     => '.active .ticket_create select[name="group_id"]',
            :value   => 'Users',
          },
          {
            :execute => 'set',
            :css     => '.active .ticket_create input[name="subject"]',
            :value   => 'test to merge',
          },
          {
            :execute => 'set',
            :css     => '.active .ticket_create textarea[name="body"]',
            :value   => 'some body 123äöü 222',
          },
          {
            :execute => 'click',
            :css     => '.active .form-actions button[type="submit"]',
          },
          {
            :execute => 'wait',
            :value   => 5,
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
            :css          => '.content_permanent.active',
            :value        => 'some body 123äöü 222',
            :match_result => true,
          },

          # update ticket
          {
            :execute => 'select',
            :css     => '.content_permanent.active select[name="ticket_article_type_id"]',
            :value   => 'note',
          },
          {
            :execute => 'check',
            :css     => '.content_permanent.active textarea[name="body"]',
            :result  => true,
          },
          {
            :execute => 'set',
            :css     => '.content_permanent.active textarea[name="body"]',
            :value   => 'some body 1234 äöüß 222',
          },
          {
            :execute => 'click',
            :css     => '.content_permanent.active button',
          },
          {
            :execute => 'wait',
            :value   => 4,
          },
          {
            :execute      => 'match',
            :css          => '.content_permanent.active .ticket-answer',
            :value        => 'some body 1234 äöüß 222',
            :match_result => true,
          },

          # check if task is shown
          {
            :execute      => 'match',
            :css          => 'body',
            :value        => 'test to merge',
            :match_result => true,
          },
        ],
      },
      {
        :name     => 'agent ticket merge',
        :action   => [
          {
            :execute => 'click',
            :css     => '.active a[data-type="merge"]',
          },
          {
            :execute => 'wait',
            :value   => 4,
          },
          {
            :execute => 'set',
            :css     => '.modal input[name="master_ticket_number"]',
            :value   => '###stack###',
          },
          {
            :execute => 'click',
            :css     => '.modal button[type="submit"]',
          },
          {
            :execute => 'wait',
            :value   => 6,
          },

          # check if megred to ticket is shown now
          {
            :execute      => 'match',
            :css          => '.active .ticket-zoom small',
            :value        => '###stack###',
            :match_result => true,
          },

          # check if task is now gone
          {
            :execute      => 'match',
            :css          => 'body',
            :value        => 'test to merge',
            :match_result => true,
          },

          # close task/cleanup
          {
            :execute => 'click',
            :css     => '#task [data-type="close"]',
          },
        ],
      },
    ]
    browser_signle_test_with_login(tests, { :username => 'agent1@example.com' })
  end
end
