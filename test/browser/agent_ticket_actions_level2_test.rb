# encoding: utf-8
require 'browser_test_helper'

class AgentTicketActionsLevel2Test < TestCase
  def test_work_with_two_browser_on_same_ticket
    message = 'message 1äöüß ' + rand(99999999999999999).to_s
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
            :css          => '.active div.article',
            :value        => 'some level 2 <b>body</b> 123äöü',
            :match_result => true,
          },

          # remember old ticket where we want to merge to
          {
            :where        => :instance1,
            :execute      => 'match',
            :css          => '.active .ticket_info h3',
            :value        => '^#(.*)$',
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
            :value   => 1,
          },
          {
            :where        => :instance2,
            :execute      => 'js',
            :value        => '$("#global-search").val("")',
          },
          {
            :where        => :instance2,
            :execute      => 'js',
            :value        => '$("#global-search").focus()',
          },
          {
            :execute => 'wait',
            :value   => 1,
          },
          {
            :where        => :instance2,
            :execute      => 'js',
            :value        => '$("#global-search").blur()',
          },
          {
            :where        => :instance2,
            :execute      => 'js',
            :value        => '$("#global-search").parent().parent().removeClass("open")',
          },
          {
            :execute => 'wait',
            :value   => 3,
          },
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => '.active div.article',
            :value        => 'some level 2 <b>body</b> 123äöü',
            :match_result => true,
          },

          # change title in second browser
#          {
#            :where        => :instance2,
#            :execute      => 'sendkey',
#            :css          => '.active .ticket-title-update',
#            :value        => 'TTT',
#          },
#          {
#            :where        => :instance2,
#            :execute      => 'sendkey',
#            :css          => '.active .ticket-title-update',
#            :value        => :tab,
#          },
          {
            :where        => :instance2,
            :execute      => 'js',
            :value        => '$(".active .ticket-title .ticket-title-update").focus()',
          },
          {
            :where        => :instance2,
            :execute      => 'js',
            :value        => '$(".active .ticket-title .ticket-title-update").html("TTTsome level 2 &lt;b&gt;subject&lt;/b&gt; 123äöü")',
          },
          {
            :where        => :instance2,
            :execute      => 'js',
            :value        => '$(".active .ticket-title .ticket-title-update").blur()',
          },
          {
            :where        => :instance2,
            :execute      => 'js',
            :value        => '$(".active .ticket-title .ticket-title-update").trigger("blur")',
          },
          {
            :execute => 'wait',
            :value   => 5,
          },

          # set body in edit area
          {
            :where   => :instance2,
            :execute => 'set',
            :css     => '.active .ticket-answer textarea[name="body"]',
            :value   => 'some level 2 <b>body</b> in instance 2',
          },
          {
            :where   => :instance1,
            :execute => 'set',
            :css     => '.active .ticket-answer textarea[name="body"]',
            :value   => 'some level 2 <b>body</b> in instance 1',
          },

          # change task and page title in second browser
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => '.taskbar .active .task',
            :value        => 'TTTsome level 2 <b>subject</b> 123äöü',
            :match_result => true,
          },
          {
            :where        => :instance2,
            :element      => :title,
            :value        => 'TTTsome level 2 <b>subject</b> 123äöü',
          },

          # change task and page title in first browser
          {
            :execute => 'wait',
            :value   => 10,
          },
          {
            :where        => :instance1,
            :execute      => 'match',
            :css          => '.active .ticket-title-update',
            :value        => 'TTTsome level 2 <b>subject</b> 123äöü',
            :match_result => true,
          },
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => '.taskbar .active .task',
            :value        => 'TTTsome level 2 <b>subject</b> 123äöü',
            :match_result => true,
          },
          {
            :where        => :instance1,
            :element      => :title,
            :value        => 'TTTsome level 2 <b>subject</b> 123äöü',
          },
          {
            :where        => :instance2,
            :element      => :title,
            :value        => 'TTTsome level 2 <b>subject</b> 123äöü',
          },

          # verify text in input body
          {
            :where        => :instance1,
            :execute      => 'match',
            :css          => '.active .ticket-answer textarea[name="body"]',
            :value        => 'some level 2 <b>body</b> in instance 1',
            :match_result => true,
          },
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => '.active .ticket-answer textarea[name="body"]',
            :value        => 'some level 2 <b>body</b> in instance 2',
            :match_result => true,
          },

          # add new article
          {
            :where   => :instance1,
            :execute => 'select',
            :css     => '.active .ticket-answer select[name="ticket_article_type_id"]',
            :value   => 'note',
          },
          {
            :where   => :instance1,
            :execute => 'set',
            :css     => '.active .ticket-answer textarea[name="body"]',
            :value   => 'some update 4711',
          },
          {
            :where   => :instance1,
            :execute => 'click',
            :css     => '.active button.submit',
          },
          {
            :where   => :instance1,
            :execute => 'watch_for',
            :area    => 'body',
            :value   => 'some update 4711',
          },

          # verify empty text in input body
          {
            :where        => :instance1,
            :execute      => 'match',
            :css          => '.active .ticket-answer textarea[name="body"]',
            :value        => '',
            :match_result => true,
          },
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => '.active .ticket-answer textarea[name="body"]',
            :value        => 'some level 2 <b>body</b> in instance 2',
            :match_result => true,
          },


          # reload instances, verify again
          {
            :where        => :instance1,
            :execute      => 'reload',
          },
          {
            :where        => :instance2,
            :execute      => 'reload',
          },

          # wait till application become ready
          {
            :execute => 'wait',
            :value   => 8,
          },
          {
            :where        => :instance1,
            :execute      => 'match',
            :css          => '.active .ticket-title-update',
            :value        => 'TTTsome level 2 <b>subject</b> 123äöü',
            :match_result => true,
          },
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => '.taskbar .active .task',
            :value        => 'TTTsome level 2 <b>subject</b> 123äöü',
            :match_result => true,
          },
          {
            :where        => :instance1,
            :element      => :title,
            :value        => 'TTTsome level 2 <b>subject</b> 123äöü',
          },
          {
            :where        => :instance2,
            :element      => :title,
            :value        => 'TTTsome level 2 <b>subject</b> 123äöü',
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
            :where        => :instance1,
            :execute      => 'match',
            :css          => '.active .ticket-answer textarea[name="body"]',
            :value        => '',
            :match_result => true,
          },
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => '.active .ticket-answer textarea[name="body"]',
            :value        => 'some level 2 <b>body</b> in instance 2',
            :match_result => true,
          },

        ],
      },
    ]
    browser_double_test(tests)
  end
end
