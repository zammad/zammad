
require 'browser_test_helper'

class AgentTicketOverviewGroupByOrganizationTest < TestCase

=begin

  Verify fix for Github issue #2046 - Special characters get HTML encoded when displayed in overviews...

=end
  def test_grouping_by_organzation_overview
    random = rand(999_999).to_s
    user_email = "user_#{random}@example.com"
    overview_name = "overview_#{random}"

    @browser = instance = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url: browser_url,
    )
    tasks_close_all()

    # 1. Create a new test organization with special characters in its name
    organization = organization_create(
      data: {
        name: 'äöüß & Test Organization',
      }
    )

    # 2. Create a new user that belongs to the test organization
    user = user_create(
      data: {
        login:     'test user',
        firstname: 'Max',
        lastname:  'Mustermann',
        email:     user_email,
        password:  'some-pass',
        organization: 'äöüß & Test Organization',
      }
    )

    # 3. Create a new ticket for the test user
    ticket = ticket_create(
      data: {
        customer: user_email,
        title:    'test ticket',
        body:     'test ticket',
        group:    'Users',
      },
    )

    # 4. Create an overview grouping by organization
    overview = overview_create(
      data: {
        name: overview_name,
        roles: %w[Agent Admin Customer],
        group_by: 'Organization',
      }
    )

    # 5. Open the newly created overview and verify that the organization name is correctly rendered
    location(url: "#{browser_url}/#ticket/view/#{overview_name}")
    sleep 1
    elements = instance.find_elements(xpath: '//b[contains(text(),"äöüß & Test Organization")]')
    elements = elements.select { |x| x.text.present? }
    assert elements
    assert_equal 'äöüß & Test Organization', elements.first.text
  end
end
