# encoding: utf-8
require 'browser_test_helper'

class AgentTicketOverviewLevel1Test < TestCase
  def test_I
    name = 'name-' + rand(999_999).to_s

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

    # keep connection alive
    click(
      :browser => browser2,
      :css     => '.search-holder',
    )

    ticket2 = ticket_create(
      :browser => browser1,
      :data    => {
        :customer => 'nico*',
        :group    => 'Users',
        :title    => 'overview #2',
        :body     => 'overview #2',
      }
    )

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
      :number  => ticket3[:number],
      :link    => '#ticket/view/' + name,
    )

    # use overview navigation to got to #2 & #3
    match(
      :browser => browser2,
      :css     => '.active .ticketZoom .overview-navigator.horizontal .pagination-counter',
      :value   => '1/',
    )
    match(
      :browser => browser2,
      :css     => '.active .page-header .ticket-number',
      :value   => ticket3[:number],
    )

    click(
      :browser => browser2,
      :css     => '.active .ticketZoom .overview-navigator.horizontal .next',
    )
    match(
      :browser => browser2,
      :css     => '.active .ticketZoom .overview-navigator.horizontal .pagination-counter',
      :value   => '2/',
    )
    match(
      :browser => browser2,
      :css     => '.active .page-header .ticket-number',
      :value   => ticket2[:number],
    )

    click(
      :browser => browser2,
      :css     => '.active .ticketZoom .overview-navigator.horizontal .next',
    )
    match(
      :browser => browser2,
      :css     => '.active .ticketZoom .overview-navigator.horizontal .pagination-counter',
      :value   => '3/',
    )
    match(
      :browser => browser2,
      :css     => '.active .page-header .ticket-number',
      :value   => ticket1[:number],
    )

    # close ticket
    sleep 2 # needed to selenium cache issues
    ticket_update(
      :browser => browser2,
      :data    => {
        :state => 'closed',
      }
    )
    sleep 8

    match(
      :browser => browser2,
      :css     => '.active .ticketZoom .overview-navigator.horizontal .pagination-counter',
      :value   => '3/',
    )
    match(
      :browser => browser2,
      :css     => '.active .page-header .ticket-number',
      :value   => ticket1[:number],
    )
    click(
      :browser => browser2,
      :css     => '.active .ticketZoom .overview-navigator.horizontal .previous',
    )

    match(
      :browser => browser2,
      :css     => '.active .ticketZoom .overview-navigator.horizontal .pagination-counter',
      :value   => '2/',
    )
    match(
      :browser => browser2,
      :css     => '.active .page-header .ticket-number',
      :value   => ticket2[:number],
    )
  end
end