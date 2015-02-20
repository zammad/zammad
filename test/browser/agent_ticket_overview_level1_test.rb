# encoding: utf-8
require 'browser_test_helper'

class AgentTicketOverviewLevel1Test < TestCase
  def test_I
    name = 'name-' + rand(999999).to_s

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

          # create new overview
          {
            :where             => :instance1,
            :execute           => 'create_overview',
            :name              => name,
            :link              => name,
            :role              => 'Agent',
            :prio              => 1000,
            'order::direction' => 'down',
          },

          # create tickets
          {
            :where   => :instance1,
            :execute => 'create_ticket',
            :group   => 'Users',
            :subject => 'overview #1',
            :body    => 'overview #1',
          },

          # remember ticket for later
          {
            :where        => :instance1,
            :execute      => 'match',
            :css          => '.active .page-header .ticket-number',
            :value        => '^(.*)$',
            :no_quote     => true,
            :match_result => true,
          },
          {
            :where   => :instance1,
            :execute => 'create_ticket',
            :group   => 'Users',
            :subject => 'overview #2',
            :body    => 'overview #2',
          },
          {
            :where   => :instance1,
            :execute => 'create_ticket',
            :group   => 'Users',
            :subject => 'overview #3',
            :body    => 'overview #3',
          },

          # click on first ticket on overview
          {
            :where   => :instance2,
            :execute => 'overview_ticket',
            :number  => '###stack###',
            :link    => name,
          },

          # use overview navigation to got to #2 & #3

        ],
      },
    ]
    browser_double_test(tests)
  end
end
