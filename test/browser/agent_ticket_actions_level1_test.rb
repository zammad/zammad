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

          # create ticket
          {
            :execute => 'create_ticket',
            :group   => 'Users',
            :subject => 'some subject 123äöü',
            :body    => 'some body 123äöü',
          },

          # check ticket
          {
            :execute      => 'match',
            :css          => '.active div.ticket-article',
            :value        => 'some body 123äöü',
            :match_result => true,
          },

          # remember old ticket where we want to merge to
          {
            :execute      => 'match',
            :css          => '.active .ticket-number',
            :value        => '^(.*)$',
            :no_quote     => true,
            :match_result => true,
          },

          # update ticket
          {
            :execute => 'select',
            :css     => '.active select[name="type_id"]',
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
            :css     => '.active button.submit',
          },
          {
            :execute => 'wait',
            :value   => 2,
          },
          {
            :execute => 'watch_for',
            :area    => 'body',
            :value   => 'some body 1234 äöüß',
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

          # create ticket
          {
            :execute => 'create_ticket',
            :group   => 'Users',
            :subject => 'test to merge',
            :body    => 'some body 123äöü 222',
          },

          # check ticket
          {
            :execute      => 'watch_for',
            :area         => '.content_permanent.active',
            :value        => 'some body 123äöü 222',
          },

          # update ticket
          {
            :execute => 'select',
            :css     => '.content_permanent.active select[name="type_id"]',
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
            :css     => '.content_permanent.active button.submit',
          },
          {
            :execute      => 'watch_for',
            :area         => '.content_permanent.active .ticket-answer',
            :value        => 'some body 1234 äöüß 222',
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
            :css     => '.active .actions',
          },
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
            :css          => '.active .ticket-number',
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
