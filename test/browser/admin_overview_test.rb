# encoding: utf-8
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

end
