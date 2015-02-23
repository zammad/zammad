# encoding: utf-8
require 'browser_test_helper'

class AgentOrganizationProfileTest < TestCase
  def test_search_and_edit_verify_in_second
    message = 'comment 1 ' + rand(99999999999999999).to_s

    browser1 = browser_instance
    login(
      :browser  => browser1,
      :username => 'master@example.com',
      :password => 'test',
      :url      => browser_url,
    )
    tasks_close_all(
      :browser => browser1,
    )

    browser2 = browser_instance
    login(
      :browser  => browser2,
      :username => 'agent1@example.com',
      :password => 'test',
      :url      => browser_url,
    )
    tasks_close_all(
      :browser => browser2,
    )

    organization_open_by_search(
      :browser => browser1,
      :value   => 'Zammad Foundation',
    )
    organization_open_by_search(
      :browser => browser2,
      :value   => 'Zammad Foundation',
    )

    # update note
    set(
      :browser => browser1,
      :css     => '.active [data-name="note"]',
      :value   => message,
    )
    click(
      :browser => browser1,
      :css     => '.active .profile',
    )

    # verify
    watch_for(
      :browser => browser2,
      :css     => '.active .profile-window',
      :value   => message,
    )
  end

  def test_search_and_edit_in_one
    message = '1 ' + rand(99999999).to_s

    @browser = browser_instance
    login(
      :username => 'master@example.com',
      :password => 'test',
      :url      => browser_url,
    )
    tasks_close_all()
    sleep 1

    # search and open org
    organization_open_by_search(
      :value => 'Zammad Foundation',
    )
    watch_for(
      :css     => '.active .profile-window',
      :value   => 'note',
    )
    watch_for(
      :css     => '.active .profile-window',
      :value   => 'member',
    )

    # update note
    set(
      :css     => '.active [data-name="note"]',
      :value   => 'some note 123'
    )
    click( :css => '.active .profile' )
    sleep 1

    # check and change note again in edit screen
    click( :css => '.active .js-action .select-arrow' )
    click( :css => '.active .js-action a[data-type="edit"]' )

    watch_for(
      :css   => '.active .modal',
      :value => 'note',
    )
    watch_for(
      :css   => '.active .modal',
      :value => 'some note 123',
    )

    set(
      :css   => '.active .modal [data-name="note"]',
      :value => 'some note abc',
    )
    click( :css => '.active .modal button.js-submit' )

    watch_for(
      :css   => '.active .profile-window',
      :value => 'some note abc',
    )

    # create new ticket
    ticket_create(
      :data => {
        :customer => 'nico',
        :group    => 'Users',
        :title    => 'org profile check ' + message,
        :body     => 'org profile check ' + message,
      },
    )
    sleep 1

    # switch to org tab, verify if ticket is shown
    organization_open_by_search(
      :value => 'Zammad Foundation',
    )
    watch_for(
      :css   => '.active .profile-window',
      :value => 'org profile check ' + message,
    )
  end
end