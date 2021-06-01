# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'browser_test_helper'

class AdminDragDropToNewGroupTest < TestCase
  def test_group_via_role
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )

    new_group_name = add_group
    new_role_name = add_role(new_group_name)
    open_user_modal do
      assign_role(new_role_name)
    end
    list_tickets
    assert get_group_element(new_group_name)
  end

  def test_new_group
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )

    new_group_name = add_group
    open_user_modal do
      assign_group(new_group_name, scroll: true)
    end
    list_tickets
    assert get_group_element(new_group_name)
  end

  private

  def add_group
    name = "dndgroup-#{rand(99_999_999)}"

    click(css: '.user-menu a[title=Admin')
    click(css: '.content.active a[href="#manage/groups"]')
    click(css: '.content.active a[data-type="new"]')

    modal_ready

    element = @browser.find_element(css: '.modal input[name=name]')
    element.clear
    element.send_keys(name)
    click(css: '.modal button.js-submit')

    sleep(1)

    name
  end

  def add_role(group_name)
    role_name = "#{group_name}-role"

    click(css: '.content.active a[href="#manage/roles"]')
    click(css: '.content.active a[data-type="new"]')

    modal_ready

    element = @browser.find_element(css: '.modal input[name=name]')
    element.clear
    element.send_keys(role_name)

    agent_permission = @browser.find_element(css: '.modal input[data-permission-name="ticket.agent"]')
    permission_id = agent_permission.attribute(:value)

    scroll_to(agent_permission.location.y)

    toggle_checkbox(@browser.find_element(css: '.modal'), "\"#{permission_id}\"") #digit-only selector fails

    assign_group(group_name)

    click(css: '.modal button.js-submit')

    sleep(1)

    role_name
  end

  def open_user_modal
    click(css: '.content.active a[href="#manage/users"]')

    user_css = '.user-list .js-tableBody tr td'
    watch_for(css: user_css)

    user_element = @browser.find_elements(css: user_css).find do |el|
      el.text.strip == 'master@example.com'
    end

    user_element.click

    modal_ready

    yield

    click(css: '.modal button.js-submit')

    sleep(1)
  end

  def scroll_to(offset_y = 'el.scrollHeight')
    scroll_script = "var el = document.getElementsByClassName('modal')[0];"
    scroll_script += "el.scrollTo(0, #{offset_y});"

    @browser.execute_script scroll_script
  end

  def assign_group(group_name, scroll: false)
    group_container = @browser.find_elements(css: '.modal .settings-list tbody tr').find do |el|
      el.find_element(css: 'td').text == group_name
    end

    assert_not_nil(group_container)

    scroll_to(group_container.location.y) if scroll

    toggle_checkbox(group_container, 'full')
  end

  def assign_role(role_name)
    role_container = @browser.find_elements(css: '.modal .checkbox > .inline-label').find do |el|
      el.find_elements(css: '.label-text').first&.text == role_name
    end

    scroll_to role_container.location.y

    assert_not_nil role_container

    role_id = role_container.find_element(css: 'input').attribute(:value)
    toggle_checkbox(role_container, "\"#{role_id}\"") #digit-only selector fails
  end

  def get_group_element(group_name)
    # wait until the scheduler pushes
    # the changes to the FE
    sleep(1.5)

    10.times do
      dnd_element = @browser.find_element(css: '.content.active .js-tableBody .item')

      window_height = @browser.execute_script('return window.innerHeight')

      offset = window_height - dnd_element.location.y - dnd_element.rect.height - 50

      @browser.action.click_and_hold(dnd_element).perform

      @browser.action.move_by(0, 100).perform

      sleep(0.5)

      @browser.action.move_by(0, offset - 100).perform

      sleep(1)

      group_containers = @browser.find_elements(css: '.batch-overlay-assign-entry[data-action=group_assign]')

      new_group_container = group_containers.find do |g|
        g.find_element(css: '.batch-overlay-assign-entry-name').text.downcase == group_name
      end

      verified = verify_group_and_contents(new_group_container)
      return true if verified

      sleep(0.5)

      @browser
        .action
        .release
        .perform
    end

    false
  end

  def verify_group_and_contents(group_container)
    return false if group_container.nil?

    group_description = group_container.find_element(css: '.batch-overlay-assign-entry-detail').text

    return false if group_description != '1 PEOPLE'

    @browser.action.move_to(group_container).perform

    users_in_group = @browser.find_elements(css: '.js-batch-assign-group-inner .batch-overlay-assign-entry[data-action=user_assign]')

    users_in_group.count == 1
  end

  def list_tickets
    click(css: '.menu-item[href="#ticket/view"]')
    click(css: '.overview-header .tabsHolder a.tab[href="#ticket/view/all_unassigned"]')
  end
end
