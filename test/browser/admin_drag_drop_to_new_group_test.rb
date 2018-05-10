require 'browser_test_helper'

class AdminDragDropToNewGroupTest < TestCase
  def test_new_group
    new_group_name = "d_n_d_group#{rand(99_999_999)}"
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url: browser_url,
    )
    tasks_close_all()

    click(css: '.user-menu a[title=Admin')
    click(css: '.content.active a[href="#manage/groups"]')
    click(css: '.content.active a[data-type="new"]')

    modal_ready

    element = @browser.find_element(css: '.modal input[name=name]')
    element.clear
    element.send_keys(new_group_name)
    click(css: '.modal button.js-submit')

    sleep(1)

    click(css: '.content.active a[href="#manage/users"]')

    user_css = '.user-list .js-tableBody tr td'
    watch_for(css: user_css)
    click(css: user_css)

    modal_ready

    scroll_script = "var el = document.getElementsByClassName('modal')[0];"
    scroll_script += 'el.scrollTo(0, el.scrollHeight);'

    @browser.execute_script scroll_script

    group = @browser.find_elements(css: '.modal .settings-list tbody tr').find do |el|
      el.find_element(css: 'td').text == new_group_name
    end

    assert_not_nil(group)

    checkbox = group.find_element(css: 'input[value=full]')

    @browser
      .action
      .move_to(checkbox, 0, 10)
      .click
      .perform

    click(css: '.modal button.js-submit')

    sleep(1)

    click(css: '.menu-item[href="#ticket/view"]')
    click(css: '.overview-header .tabsHolder a.tab[href="#ticket/view/all_unassigned"]')

    element = @browser.find_element(css: '.js-tableBody .item')

    @browser
      .action
      .click_and_hold(element)
      .move_by(100, 100)
      .perform

    sleep(1)

    @browser
      .action
      .move_to(@browser.find_element(css: '.js-batch-assign-circle'))
      .perform

    sleep(1)

    group_containers = @browser.find_elements(css: '.batch-overlay-assign-entry[data-action=group_assign]')

    new_group_container = group_containers.find do |g|
      g.find_element(css: '.batch-overlay-assign-entry-name').text.downcase == new_group_name
    end

    assert_not_nil new_group_container

    group_description = new_group_container.find_element(css: '.batch-overlay-assign-entry-detail').text
    assert_equal('1 PEOPLE', group_description)
  end
end
