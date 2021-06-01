# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class AdminOverviewTest < TestCase
  def test_account_add
    name = "some overview #{rand(99_999_999)}"

    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    # add new overview
    overview_create(
      data: {
        name: name,
        roles: ['Agent'],
        selector: {
          'Priority' => '1 low',
        },
        'order::direction' => 'down',
      }
    )

    # edit overview
    overview_update(
      data: {
        name: name,
        roles: ['Agent'],
        selector: {
          'State' => 'new',
        },
        'order::direction' => 'up',
      }
    )
  end

  def test_overview_group_by_direction
    name = "overview_#{rand(99_999_999)}"
    ticket_titles = (1..3).map { |i| "Priority #{i} ticket" }

    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    'Priority 1 ticket',
        body:     'some body 123äöü',
        priority: '1 low',
      },
    )

    ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    'Priority 2 ticket',
        body:     'some body 123äöü',
        priority: '2 normal',
      },
    )

    ticket_create(
      data: {
        customer: 'nico',
        group:    'Users',
        title:    'Priority 3 ticket',
        body:     'some body 123äöü',
        priority: '3 high',
      },
    )

    # Add new overview to sort groups from high to low
    overview_create(
      data: {
        name: name,
        roles: ['Agent'],
        selector: {
          'State' => 'open',
        },
        'order::direction' => 'down',
        group_by: 'Priority',
        group_direction: 'down',
      }
    )

    overview_open(
      name: name
    )

    assert_equal(ticket_titles.reverse, ordered_ticket_titles(ticket_titles))

    # Update overview to sort groups from low to high
    overview_update(
      data: {
        name:            name,
        group_direction: 'up',
      }
    )

    overview_open(
      name: name
    )

    # wait till the scheduler pushed
    # the changes to the FE
    sleep 5

    assert_equal(ticket_titles, ordered_ticket_titles(ticket_titles))
  end

  def ordered_ticket_titles(ticket_titles)
    ticket_titles.map do |title|
      [title,
       get_location( css: "td[title='#{title}']").y]
    end.sort_by { |x| x[1] }.map { |x| x[0] }
  end

  # verify fix for issue #2235 - Overview setting isn't applied on submit
  def test_overview_toggle_out_of_office_setting
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )
    tasks_close_all()

    out_of_office_css = '.content.active .modal select[name="out_of_office"]'
    first_overview_css = '.content.active tr[data-id="1"] td'

    click( css: 'a[href="#manage"]' )
    click( css: '.content.active a[href="#manage/overviews"]' )

    # round 1, open the overview and set out_of_office to true
    click( css: first_overview_css )
    modal_ready
    watch_for(
      css:   out_of_office_css,
      value: 'no',
    )
    select(
      css:   out_of_office_css,
      value: 'yes',
    )
    click( css: '.content.active .modal .js-submit' )
    modal_disappear

    # round 2, open the overview and set out_of_office back to false
    click( css: first_overview_css )
    modal_ready
    watch_for(
      css:   out_of_office_css,
      value: 'yes',
    )
    select(
      css:   out_of_office_css,
      value: 'no',
    )
    click( css: '.content.active .modal .js-submit' )
    modal_disappear

    # round 3, open the overview and confirm that it's still false
    click( css: first_overview_css )
    modal_ready
    watch_for(
      css:   out_of_office_css,
      value: 'no',
    )
    click( css: '.content.active .modal .js-submit' )
    modal_disappear
  end
end
