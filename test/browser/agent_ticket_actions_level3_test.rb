# encoding: utf-8
require 'browser_test_helper'

class AgentTicketActionsLevel3Test < TestCase
  def test_work_with_two_browser_on_same_ticket_edit
    message = 'message 3 äöüß ' + rand(99999999999999999).to_s
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
            :execute => 'check',
            :css     => '#login',
            :result  => false,
          },
          {
            :where   => :instance2,
            :execute => 'check',
            :css     => '#login',
            :result  => false,
          },
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
            :execute => 'click',
            :css     => 'a[href="#new"]',
          },
          {
            :where   => :instance1,
            :execute => 'click',
            :css     => 'a[href="#ticket_create/call_inbound"]',
          },
          {
            :execute => 'wait',
            :value   => 5,
          },
          {
            :where   => :instance1,
            :execute => 'check',
            :css     => '.active .ticket_create',
            :result  => true,
          },
          {
            :where   => :instance1,
            :execute => 'set',
            :css     => '.active .ticket_create input[name="customer_id_autocompletion"]',
            :value   => 'ma',
          },
          {
            :execute => 'wait',
            :value   => 4,
          },
          {
            :where   => :instance1,
            :execute => 'sendkey',
            :css     => '.active .ticket_create input[name="customer_id_autocompletion"]',
            :value   => :arrow_down,
          },
          {
            :where   => :instance1,
            :execute => 'sendkey',
            :css     => '.active .ticket_create input[name="customer_id_autocompletion"]',
            :value   => :tab,
          },
          {
            :where   => :instance1,
            :execute => 'select',
            :css     => '.active .ticket_create select[name="group_id"]',
            :value   => 'Users',
          },
          {
            :where   => :instance1,
            :execute => 'set',
            :css     => '.active .ticket_create input[name="subject"]',
            :value   => 'some level 3 <b>subject</b> 123äöü',
          },
          {
            :where   => :instance1,
            :execute => 'set',
            :css     => '.active .ticket_create textarea[name="body"]',
            :value   => 'some level 3 <b>body</b> 123äöü',
          },
          {
            :where   => :instance1,
            :execute => 'click',
            :css     => '.active .form-actions button[type="submit"]',
          },
          {
            :execute => 'wait',
            :value   => 6,
          },
          {
            :where   => :instance1,
            :execute => 'check',
            :element => :url,
            :result  => '#ticket/zoom/',
          },

          # check ticket
          {
            :where        => :instance1,
            :execute      => 'match',
            :css          => '.active div.article',
            :value        => 'some level 3 <b>body</b> 123äöü',
            :match_result => true,
          },

          # remember old ticket where we want to merge to
          {
            :where   => :instance1,
            :execute      => 'match',
            :css          => '.active .ticket-zoom small',
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
            :value        => 'some level 3 <b>body</b> 123äöü',
            :match_result => true,
          },

          # change edit screen in instance 1
          {
            :where   => :instance1,
            :execute => 'set',
            :css     => '.active .ticket-answer textarea[name="body"]',
            :value   => 'some level 3 <b>body</b> in instance 1',
          },
          {
            :execute => 'wait',
            :value   => 3,
          },

          # update ticket in instance 2
          {
            :where   => :instance2,
            :execute => 'set',
            :css     => '.active .ticket-answer textarea[name="body"]',
            :value   => 'some level 3 <b>body</b> in instance 2',
          },
          {
            :execute => 'wait',
            :value   => 1,
          },
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => '.content_permanent.active',
            :value        => 'Discard your unsaved changes.',
            :match_result => true,
          },
          {
            :where   => :instance2,
            :execute => 'click',
            :css     => '.active .edit button[type="submit"]',
          },
          {
            :execute => 'wait',
            :value   => 8,
          },
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => '.content_permanent.active',
            :value        => 'Discard your unsaved changes.',
            :match_result => false,
          },

          # check content and edit screen in instance 1
          {
            :where        => :instance1,
            :execute      => 'match',
            :css          => '.active div.article-view',
            :value        => 'some level 3 <b>body</b> in instance 2',
            :match_result => true,
          },
          {
            :where        => :instance1,
            :execute      => 'match',
            :css          => '.active .ticket-answer textarea[name="body"]',
            :value        => 'some level 3 <b>body</b> in instance 1',
            :match_result => true,
          },
          {
            :where        => :instance1,
            :execute      => 'match',
            :css          => '.content_permanent.active',
            :value        => 'Discard your unsaved changes.',
            :match_result => true,
          },

          # check edit screen in instance 2
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => '.active .ticket-answer textarea[name="body"]',
            :value        => '^$',
            :no_quote     => true,
            :match_result => true,
          },

          # update ticket in instance 1
          {
            :where   => :instance1,
            :execute => 'click',
            :css     => '.active .edit button[type="submit"]',
          },
          {
            :execute => 'wait',
            :value   => 8,
          },

          # check content in instance 2
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => '.active div.article-view',
            :value        => 'some level 3 <b>body</b> in instance 1',
            :match_result => true,
          },
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => '.active div.article-view',
            :value        => 'some level 3 <b>body</b> in instance 2',
            :match_result => true,
          },

          # check content and edit screen in instance 1+2
          {
            :where        => :instance1,
            :execute      => 'match',
            :css          => '.active .ticket-answer textarea[name="body"]',
            :value        => '^$',
            :no_quote     => true,
            :match_result => true,
          },
          {
            :where        => :instance1,
            :execute      => 'match',
            :css          => '.content_permanent.active',
            :value        => 'Discard your unsaved changes.',
            :match_result => false,
          },
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => '.active .ticket-answer textarea[name="body"]',
            :value        => '^$',
            :no_quote     => true,
            :match_result => true,
          },
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => '.content_permanent.active',
            :value        => 'Discard your unsaved changes.',
            :match_result => false,
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

          # check content and edit screen in instance 1+2
          {
            :where        => :instance1,
            :execute      => 'match',
            :css          => '.active .ticket-answer textarea[name="body"]',
            :value        => '^$',
            :no_quote     => true,
            :match_result => true,
          },
          {
            :where        => :instance1,
            :execute      => 'match',
            :css          => '.content_permanent.active',
            :value        => 'Discard your unsaved changes.',
            :match_result => false,
          },
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => '.active .ticket-answer textarea[name="body"]',
            :value        => '^$',
            :no_quote     => true,
            :match_result => true,
          },
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => '.content_permanent.active',
            :value        => 'Discard your unsaved changes.',
            :match_result => false,
          },

          # change form of ticket in instance 2
          {
            :where   => :instance2,
            :execute => 'set',
            :css     => '.active .ticket-answer textarea[name="body"]',
            :value   => '22 some level 3 <b>body</b> in instance 2',
          },
          {
            :execute => 'wait',
            :value   => 2,
          },
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => '.content_permanent.active',
            :value        => 'Discard your unsaved changes.',
            :match_result => true,
          },
          {
            :where        => :instance2,
            :execute      => 'reload',
          },
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => '.active .ticket-answer textarea[name="body"]',
            :value        => '22 some level 3 <b>body</b> in instance 2',
            :match_result => true,
          },
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => '.content_permanent.active',
            :value        => 'Discard your unsaved changes.',
            :match_result => true,
          },
          {
            :where   => :instance2,
            :execute => 'click',
            :css     => '.active .edit button[type="submit"]',
          },
          {
            :execute => 'wait',
            :value   => 8,
          },
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => '.content_permanent.active',
            :value        => 'Discard your unsaved changes.',
            :match_result => false,
          },
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => '.active div.article-view',
            :value        => '22 some level 3 <b>body</b> in instance 2',
            :match_result => true,
          },
        ],
      },
    ]
    browser_double_test(tests)
  end
end
