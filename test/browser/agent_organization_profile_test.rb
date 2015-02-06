# encoding: utf-8
require 'browser_test_helper'

class AgentOrganizationProfileTest < TestCase
  def test_search_and_edit_verify_in_second
    message = 'comment 1 ' + rand(99999999999999999).to_s
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
          {
            :where   => :instance1,
            :execute => 'search_organization',
            :term    => 'Zammad',
          },
          {
            :where   => :instance2,
            :execute => 'search_organization',
            :term    => 'Zammad',
          },

          # update note
          {
            :where   => :instance1,
            :execute => 'set',
            :css     => '.active [data-name="note"]',
            :value   => message,
          },
          {
            :where   => :instance1,
            :execute => 'click',
            :css     => '.active .profile',
          },
          {
            :where   => :instance1,
            :execute => 'wait',
            :value   => 3,
          },

          # verify
          {
            :where        => :instance2,
            :execute      => 'match',
            :css          => '.active .profile-window',
            :value        => message,
            :match_result => true,
          },
        ],
      },
    ]
    browser_double_test(tests)
  end

  def test_search_and_edit_in_one
    message = '1 ' + rand(99999999).to_s
    tests = [
      {
        :name   => 'search and edit',
        :action => [
          {
            :execute => 'close_all_tasks',
          },

          # search and open org
          {
            :execute => 'search_organization',
            :term    => 'Zammad',
          },
          {
            :execute      => 'match',
            :css          => '.active .profile-window',
            :value        => 'note',
            :match_result => true,
          },
          {
            :execute      => 'match',
            :css          => '.active .profile-window',
            :value        => 'member',
            :match_result => true,

          },

          # update note
          {
            :execute => 'set',
            :css     => '.active [data-name="note"]',
            :value   => 'some note 123'
          },
          {
            :execute => 'click',
            :css     => '.active .profile',
          },
          {
            :execute => 'wait',
            :value   => 1,
          },

          # check and change note again in edit screen
          {
            :execute => 'click',
            :css     => '.active .js-action .select-arrow',
          },
          {
            :execute => 'click',
            :css     => '.active .js-action a[data-type="edit"]',
          },
          {
            :execute => 'wait',
            :value   => 1,
          },
          {
            :execute      => 'match',
            :css          => '.active .modal',
            :value        => 'note',
            :match_result => true,
          },
          {
            :execute      => 'match',
            :css          => '.active .modal',
            :value        => 'some note 123',
            :match_result => true,
          },
          {
            :execute => 'set',
            :css     => '.active .modal [data-name="note"]',
            :value   => 'some note abc'
          },
          {
            :execute => 'click',
            :css     => '.active .modal button.js-submit',
          },
          {
            :execute => 'wait',
            :value   => 4,
          },
          {
            :execute      => 'match',
            :css          => '.active .profile-window',
            :value        => 'some note abc',
            :match_result => true,
          },

          # create new ticket
          {
            :execute => 'create_ticket',
            :group   => 'Users',
            :subject => 'org profile check ' + message,
            :body    => 'org profile check ' + message,
          },
          {
            :execute => 'wait',
            :value   => 4,
          },

          # switch to org tab, verify if ticket is shown
          {
            :execute => 'search_organization',
            :term    => 'Zammad',
          },

          {
            :execute      => 'match',
            :css          => '.active .profile-window',
            :value        => 'org profile check ' + message,
            :match_result => true,
          },

        ],
      },
    ]
    browser_signle_test_with_login(tests, { :username => 'master@example.com' })
  end
end