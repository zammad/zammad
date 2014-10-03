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
            :subject => 'some level 3 <b>subject</b> 123äöü',
            :body    => 'some level 3 <b>body</b> 123äöü',
          },

          # check ticket
          {
            :where        => :instance1,
            :execute      => 'match',
            :css          => '.active div.ticket-article',
            :value        => 'some level 3 <b>body</b> 123äöü',
            :match_result => true,
          },

          # remember old ticket where we want to merge to
          {
            :where        => :instance1,
            :execute      => 'match',
            :css          => '.active .page-header .ticket-number',
            :value        => '^#(.*)$',
            :no_quote     => true,
            :match_result => true,
          },

          # open ticket in second browser
          {
            :execute => 'wait',
            :value   => 1,
          },
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
            :value        => 'some level 3 <b>body</b> 123äöü',
            :match_result => true,
          },

          # change edit screen in instance 1
          {
            :where   => :instance1,
            :execute => 'set',
            :css     => '.active .ticket-edit textarea[name="body"]',
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
            :css     => '.active .ticket-edit textarea[name="body"]',
            :value   => 'some level 3 <b>body</b> in instance 2',
          },
          {
            :execute => 'wait',
            :value   => 5,
          },
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => '.content_permanent.active .reset-message',
            :value        => '(Discard your unsaved changes.|Verwerfen der)',
            :no_quote     => true,
            :match_result => true,
          },
          {
            :where   => :instance2,
            :execute => 'click',
            :css     => '.active .edit button[type="submit"]',
          },
          {
            :execute => 'wait',
            :value   => 12,
          },
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => '.content_permanent.active .reset-message',
            :value        => '(Discard your unsaved changes.|Verwerfen der)',
            :no_quote     => true,
            :match_result => false,
          },

          # check content and edit screen in instance 1
          {
            :where        => :instance1,
            :execute      => 'match',
            :css          => '.active div.ticket-article-view',
            :value        => 'some level 3 <b>body</b> in instance 2',
            :match_result => true,
          },
          {
            :where        => :instance1,
            :execute      => 'match',
            :css          => '.active .ticket-edit textarea[name="body"]',
            :value        => 'some level 3 <b>body</b> in instance 1',
            :match_result => true,
          },
          {
            :where        => :instance1,
            :execute      => 'match',
            :css          => '.content_permanent.active .reset-message',
            :value        => '(Discard your unsaved changes.|Verwerfen der)',
            :no_quote     => true,
            :match_result => true,
          },

          # check edit screen in instance 2
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => '.active .ticket-edit textarea[name="body"]',
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
            :value   => 16,
          },

          # check content in instance 2
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => '.active div.ticket-article-view',
            :value        => 'some level 3 <b>body</b> in instance 1',
            :match_result => true,
          },
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => '.active div.ticket-article-view',
            :value        => 'some level 3 <b>body</b> in instance 2',
            :match_result => true,
          },

          # check content and edit screen in instance 1+2
          {
            :where        => :instance1,
            :execute      => 'match',
            :css          => '.active .ticket-edit textarea[name="body"]',
            :value        => '^$',
            :no_quote     => true,
            :match_result => true,
          },
          {
            :where        => :instance1,
            :execute      => 'match',
            :css          => '.content_permanent.active .reset-message',
            :value        => '(Discard your unsaved changes.|Verwerfen der)',
            :no_quote     => true,
            :match_result => false,
          },
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => '.active .ticket-edit textarea[name="body"]',
            :value        => '^$',
            :no_quote     => true,
            :match_result => true,
          },
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => '.content_permanent.active .reset-message',
            :value        => '(Discard your unsaved changes.|Verwerfen der)',
            :no_quote     => true,
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
            :css          => '.active .ticket-edit textarea[name="body"]',
            :value        => '^$',
            :no_quote     => true,
            :match_result => true,
          },
          {
            :where        => :instance1,
            :execute      => 'match',
            :css          => '.content_permanent.active .reset-message',
            :value        => '(Discard your unsaved changes.|Verwerfen der)',
            :no_quote     => true,
            :match_result => false,
          },
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => '.active .ticket-edit textarea[name="body"]',
            :value        => '^$',
            :no_quote     => true,
            :match_result => true,
          },
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => '.content_permanent.active .reset-message',
            :value        => '(Discard your unsaved changes.|Verwerfen der)',
            :no_quote     => true,
            :match_result => false,
          },

          # change form of ticket in instance 2
          {
            :where   => :instance2,
            :execute => 'set',
            :css     => '.active .ticket-edit textarea[name="body"]',
            :value   => '22 some level 3 <b>body</b> in instance 2',
          },
          {
            :execute => 'wait',
            :value   => 4,
          },
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => '.content_permanent.active .reset-message',
            :value        => '(Discard your unsaved changes.|Verwerfen der)',
            :no_quote     => true,
            :match_result => true,
          },
          {
            :where        => :instance2,
            :execute      => 'reload',
          },
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => '.active .ticket-edit textarea[name="body"]',
            :value        => '22 some level 3 <b>body</b> in instance 2',
            :match_result => true,
          },
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => '.content_permanent.active .reset-message',
            :value        => '(Discard your unsaved changes.|Verwerfen der)',
            :no_quote     => true,
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
            :css          => '.content_permanent.active .reset-message',
            :value        => '(Discard your unsaved changes.|Verwerfen der)',
            :no_quote     => true,
            :match_result => false,
          },
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => '.active div.ticket-article-view',
            :value        => '22 some level 3 <b>body</b> in instance 2',
            :match_result => true,
          },
        ],
      },
    ]
    browser_double_test(tests)
  end
end
