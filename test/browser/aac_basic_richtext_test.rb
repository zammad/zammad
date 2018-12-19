require 'browser_test_helper'

class AACBasicRichtextTest < TestCase
  def test_richtext
    @browser = browser_instance
    login(
      username: 'master@example.com',
      password: 'test',
      url:      browser_url,
    )

    click(css: 'a[href="#current_user"]')
    click(css: 'a[href="#layout_ref"]')
    click(css: 'a[href="#layout_ref/richtext"]')
    click(css: 'a[href="#current_user"]')

    # richtext single line
    set(
      css:   '#content .text-1',
      value: 'some test for browser ',
      slow:  true,
    )
    sleep 1
    sendkey(value: :enter)
    sendkey(value: 'and some other for browser')
    sleep 1

    match(
      css:   '#content .text-1',
      value: 'some test for browser and some other for browser',
    )

    # text multi line
    set(
      css:   '#content .text-3',
      value: 'some test for browser ',
      slow:  true,
    )
    sleep 1
    sendkey(value: :enter)
    sendkey(value: 'and some other for browser')
    sleep 1

    match(
      css:     '#content .text-3',
      value:   "some test for browser\nand some other for browser",
      cleanup: true,
    )

    # richtext multi line
    set(
      css:   '#content .text-5',
      value: 'some test for browser ',
      slow:  true,
    )
    sleep 1
    sendkey(value: :enter)
    sendkey(value: 'and some other for browser2')
    sleep 1

    match(
      css:     '#content .text-5',
      value:   "some test for browser\nand some other for browser2",
      cleanup: true,
    )
  end
end
