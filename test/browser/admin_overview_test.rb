
require 'browser_test_helper'

class AdminOverviewTest < TestCase
  def test_account_add
    name = "some overview #{rand(99_999_999)}"

    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url: browser_url,
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

    @browser = instance = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url: browser_url,
    )
    tasks_close_all()

    ticket_create(
      data: {
        customer: 'nico',
        group: 'Users',
        title: 'Priority 1 ticket',
        body: 'some body 123äöü',
        priority: '1 low',
      },
    )

    ticket_create(
      data: {
        customer: 'nico',
        group: 'Users',
        title: 'Priority 2 ticket',
        body: 'some body 123äöü',
        priority: '2 normal',
      },
    )

    ticket_create(
      data: {
        customer: 'nico',
        group: 'Users',
        title: 'Priority 3 ticket',
        body: 'some body 123äöü',
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

    click(
      browser: instance,
      css:  'a[href="#ticket/view"]',
      mute_log: true,
    )
    click(
      browser: instance,
      css:  "div.overview-header a[href='#ticket/view/#{name}']",
      mute_log: true,
    )

    # Sort the tickets according to their onscreen Y location
    tickets_low_to_high = ticket_titles.map do |title|
      [title,
       get_location( css: "td[title='#{title}']").y]
    end
    tickets_low_to_high = tickets_low_to_high.sort_by { |x| -x[1] }.map { |x| x[0] }
    assert_equal(ticket_titles, tickets_low_to_high)

    # Update overview to sort groups from low to high
    overview_update(
      data: {
        name: name,
        group_direction: 'up',
      }
    )

    click(
      browser: instance,
      css:  'a[href="#ticket/view"]',
      mute_log: true,
    )
    click(
      browser: instance,
      css:  "div.overview-header a[href='#ticket/view/#{name}']",
      mute_log: true,
    )

    # Sort the tickets according to their onscreen Y location
    tickets_high_to_low = ticket_titles.map do |title|
      [title,
       get_location( css: "td[title='#{title}']").y]
    end
    tickets_high_to_low = tickets_high_to_low.sort_by { |x| x[1] }.map { |x| x[0] }
    assert_equal(ticket_titles, tickets_high_to_low)
  end
end
