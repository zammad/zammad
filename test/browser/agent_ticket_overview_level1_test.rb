# encoding: utf-8
require 'browser_test_helper'

class AgentTicketOverviewLevel1Test < TestCase
  def test_I
    name = 'name-' + rand(999999).to_s

    browser1 = browser_instance
    login(
      :browser  => browser1,
      :username => 'master@example.com',
      :password => 'test',
      :url      => browser_url,
    )
    tasks_close_all( :browser => browser1 )

    browser2 = browser_instance
    login(
      :browser  => browser2,
      :username => 'agent1@example.com',
      :password => 'test',
      :url      => browser_url,
    )
    tasks_close_all( :browser => browser2 )

    # create new overview
    overview = overview_create(
      :browser => browser1,
      :data    => {
        :name              => name,
        :link              => name,
        :role              => 'Agent',
        :prio              => 1000,
        'order::direction' => 'down',
      }
    )
    sleep 1

    # create tickets
    ticket1 = ticket_create(
      :browser => browser1,
      :data    => {
        :customer => 'nico*',
        :group    => 'Users',
        :title    => 'overview #1',
        :body     => 'overview #1',
      }
    )
    sleep 1

    ticket2 = ticket_create(
      :browser => browser1,
      :data    => {
        :customer => 'nico*',
        :group    => 'Users',
        :title    => 'overview #2',
        :body     => 'overview #2',
      }
    )
    sleep 1

    ticket3 = ticket_create(
      :browser => browser1,
      :data    => {
        :customer => 'nico*',
        :group    => 'Users',
        :title    => 'overview #3',
        :body     => 'overview #3',
      }
    )

    # click on #1 on overview
    ticket_open_by_overview(
      :browser => browser2,
      :number  => ticket1[:number],
      :link    => '#ticket/view/' + name,
    )

    # use overview navigation to got to #2 & #3
    match(
      :browser => browser2,
      :css     => '.active .ticketZoom .overview-navigator .pagination-counter',
      :value   => '1/3',
    )
    match(
      :browser => browser2,
      :css     => '.active .page-header .ticket-number',
      :value   => ticket1[:number],
    )

    click(
      :browser => browser2,
      :css     => '.ticketZoom .overview-navigator .next',
    )
    match(
      :browser => browser2,
      :css     => '.active .ticketZoom .overview-navigator .pagination-counter',
      :value   => '2/3',
    )
    match(
      :browser => browser2,
      :css     => '.active .page-header .ticket-number',
      :value   => ticket2[:number],
    )

    click(
      :browser => browser2,
      :css     => '.ticketZoom .overview-navigator .next',
    )
    match(
      :browser => browser2,
      :css     => '.active .ticketZoom .overview-navigator .pagination-counter',
      :value   => '3/3',
    )
    match(
      :browser => browser2,
      :css     => '.active .page-header .ticket-number',
      :value   => ticket3[:number],
    )

    # close ticket
    ticket_update(
      :browser => browser2,
      :data    => {
        :state => 'closed',
      }
    )
    sleep 8

    match(
      :browser => browser2,
      :css     => '.active .ticketZoom .overview-navigator .pagination-counter',
      :value   => '3/3',
    )
    match(
      :browser => browser2,
      :css     => '.active .page-header .ticket-number',
      :value   => ticket3[:number],
    )
    click(
      :browser => browser2,
      :css => '.ticketZoom .overview-navigator .previous',
    )

    match(
      :browser => browser2,
      :css     => '.active .ticketZoom .overview-navigator .pagination-counter',
      :value   => '2/2',
    )
    match(
      :browser => browser2,
      :css     => '.active .page-header .ticket-number',
      :value   => ticket2[:number],
    )
  end
end