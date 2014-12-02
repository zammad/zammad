# encoding: utf-8
require 'browser_test_helper'

class AgentTicketActionsLevel2Test < TestCase
  def test_work_with_two_browser_on_same_ticket
    message = 'message 1äöüß ' + rand(99999999999999999).to_s
    tests = [
      {
        :name               => 'start',
        :instance1          => browser_instance,
        :instance2          => browser_instance,
        :instance1_username => 'master@example.com',
        :instance1_password => 'test',
        :instance2_username => 'agent1@example.com',
        :instance2_password => 'test',
        :url                => browser_url,
        :action             => [
          {
            :where   => :instance1,
            :execute => 'close_all_tasks',
          },
          {
            :where   => :instance2,
            :execute => 'close_all_tasks',
          },

          # create ticket
          {
            :where   => :instance1,
            :execute => 'create_ticket',
            :group   => 'Users',
            :subject => 'some level 2 <b>subject</b> 123äöü',
            :body    => 'some level 2 <b>body</b> 123äöü',
          },

          # check ticket
          {
            :where        => :instance1,
            :execute      => 'match',
            :css          => '.active div.ticket-article',
            :value        => 'some level 2 <b>body</b> 123äöü',
            :match_result => true,
          },

          # remember old ticket where we want to merge to
          {
            :where        => :instance1,
            :execute      => 'match',
            :css          => '.active .page-header .ticket-number',
            :value        => '^(.*)$',
            :no_quote     => true,
            :match_result => true,
          },

          # open ticket in second browser
          {
            :where   => :instance2,
            :execute => 'set',
            :css     => '#global-search',
            :value   => '###stack###',
          },
          {
            :execute => 'wait',
            :value   => 3,
          },
          {
            :where   => :instance2,
            :execute => 'click',
            :link    => '###stack###',
#            :css     => 'a:contains(\'###stack###\')',
          },
          {
            :execute => 'wait',
            :value   => 3,
          },
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => '.active div.ticket-article',
            :value        => 'some level 2 <b>body</b> 123äöü',
            :match_result => true,
          },

          # change title in second browser
          {
            :where   => :instance2,
            :execute => 'set_ticket_attributes',
            :title   => 'TTTsome level 2 <b>subject</b> 123äöü',
          },

          # set body in edit area
          {
            :where   => :instance2,
            :execute => 'set_ticket_attributes',
            :body    => 'some level 2 <b>body</b> in instance 2',
          },
          {
            :where   => :instance1,
            :execute => 'set_ticket_attributes',
            :body    => 'some level 2 <b>body</b> in instance 1',
          },

          # change task and page title in second browser
          {
            :where   => :instance2,
            :execute => 'verify_task_attributes',
            :title   => 'TTTsome level 2 <b>subject</b> 123äöü',
          },
          {
            :where   => :instance2,
            :element => :title,
            :value   => 'TTTsome level 2 <b>subject</b> 123äöü',
          },

          # change task and page title in first browser
          {
            :execute => 'wait',
            :value   => 10,
          },
          {
            :where   => :instance1,
            :execute => 'verify_ticket_attributes',
            :title   => 'TTTsome level 2 <b>subject</b> 123äöü',
          },
          {
            :where   => :instance2,
            :execute => 'verify_task_attributes',
            :title   => 'TTTsome level 2 <b>subject</b> 123äöü',
          },
          {
            :where   => :instance1,
            :element => :title,
            :value   => 'TTTsome level 2 <b>subject</b> 123äöü',
          },
          {
            :where   => :instance2,
            :element => :title,
            :value   => 'TTTsome level 2 <b>subject</b> 123äöü',
          },

          # verify text in input body
          {
            :where   => :instance1,
            :execute => 'verify_ticket_attributes',
            :body    => 'some level 2 <b>body</b> in instance 1',
          },
          {
            :where   => :instance2,
            :execute => 'verify_ticket_attributes',
            :body    => 'some level 2 <b>body</b> in instance 2',
          },

          # add new article
          #{
          #  :where   => :instance1,
          #  :execute => 'select',
          #  :css     => '.active .ticket-edit select[name="type_id"]',
          #  :value   => 'note',
          #},
          {
            :where   => :instance1,
            :execute => 'set_ticket_attributes',
            :body    => 'some update 4711',
          },
          {
            :where   => :instance1,
            :execute => 'click',
            :css     => '.content.active button.js-submit',
          },
          {
            :where   => :instance1,
            :execute => 'watch_for',
            :area    => '.active div.ticket-article',
            :value   => 'some update 4711',
          },

          # verify empty text in input body
          {
            :where   => :instance1,
            :execute => 'verify_ticket_attributes',
            :body    => '',
          },
          {
            :where   => :instance2,
            :execute => 'verify_ticket_attributes',
            :body    => 'some level 2 <b>body</b> in instance 2',
          },
          {
            :execute => 'wait',
            :value   => 3,
          },

          # reload instances, verify again
          {
            :where   => :instance1,
            :execute => 'reload',
          },
          {
            :where   => :instance2,
            :execute => 'reload',
          },

          # wait till application become ready
          {
            :execute => 'wait',
            :value   => 8,
          },
          {
            :where   => :instance1,
            :execute => 'verify_ticket_attributes',
            :title   => 'TTTsome level 2 <b>subject</b> 123äöü',
          },
          {
            :where   => :instance2,
            :execute => 'verify_task_attributes',
            :title   => 'TTTsome level 2 <b>subject</b> 123äöü',
          },
          {
            :where   => :instance1,
            :element => :title,
            :value   => 'TTTsome level 2 <b>subject</b> 123äöü',
          },
          {
            :where   => :instance2,
            :element => :title,
            :value   => 'TTTsome level 2 <b>subject</b> 123äöü',
          },

          # verify update
          {
            :where        => :instance1,
            :execute      => 'match',
            :css          => 'body',
            :value        => 'some update 4711',
            :match_result => true,
          },
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => 'body',
            :value        => 'some update 4711',
            :match_result => true,
          },

          # verify empty text in input body
          {
            :where   => :instance1,
            :execute => 'verify_ticket_attributes',
            :body    => '',
          },
          {
            :where   => :instance2,
            :execute => 'verify_ticket_attributes',
            :body    => 'some level 2 <b>body</b> in instance 2',
          },

        ],
      },
    ]
    browser_double_test(tests)
  end
end
