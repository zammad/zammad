
require 'browser_test_helper'

class AdminOrganizationSelectionTest < TestCase
  def test_organization_selection
    @browser = instance = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url: browser_url,
    )
    tasks_close_all()

    # create 4 new organizations, 2 active and 2 inactive
    created_names = Set.new()
    (0..3).each do |i|
      active = i.odd?
      active_text = active ? 'Active' : 'Inactive'
      name = "#{active_text} Test Organization #{i}"
      created_names.add(name) if active
      organization_create(
        data: {
          name: name,
          active: active,
        }
      )
    end

    # attempt to create new SLA
    click(
      browser: instance,
      css:  'a[href="#manage"]',
      mute_log: true,
    )
    click(
      browser: instance,
      css:  '.content.active a[href="#manage/slas"]',
      mute_log: true,
    )
    click(
      browser: instance,
      css:  '.content.active a.btn--success',
      mute_log: true,
    )
    modal_ready(browser: instance)
    select(
      browser:  instance,
      css:      '.modal .js-attributeSelector select',
      value:    'Organization',
      mute_log: true,
    )
    select(
      browser:  instance,
      css:      '.modal .js-preCondition select',
      value:    'specific organization',
      mute_log: true,
    )
    set(
      browser:  instance,
      css:      '.modal .searchableSelect-main',
      value:    'Test Organization',
      mute_log: true,
    )

    sleep 3
    found_names = instance.find_elements(css: '.searchableSelect-option-text').map(&:text)
    found_names = Set.new(found_names)

    assert_equal created_names, found_names
  end
end
