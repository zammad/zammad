# encoding: utf-8
require 'browser_test_helper'

class AgentTicketActionLevel8Test < TestCase
  def test_tags

    @browser = browser_instance
    login(
      username: 'agent1@example.com',
      password: 'test',
      url: browser_url,
    )
    tasks_close_all()

    # create new ticket
    ticket1 = ticket_create(
      data: {
        customer: 'nico',
        group: 'Users',
        title: 'some subject 123äöü - tags',
        body: 'some body 123äöü - tags',
      },
    )

    # set tag #1
    click(
      css: '.content.active .js-newTagLabel',
    )
    set(
      css: '.content.active .js-newTagInput',
      value: 'tag1',
    )
    sendkey(
      value: :enter,
    )

    # set tag #2
    click(
      css: '.content.active .js-newTagLabel',
    )
    set(
      css: '.content.active .js-newTagInput',
      value: 'tag 2',
    )
    sendkey(
      value: :enter,
    )

    # set tag #3 + #4
    click(
      css: '.content.active .js-newTagLabel',
    )
    set(
      css: '.content.active .js-newTagInput',
      value: 'tag3, tag4',
    )
    sendkey(
      value: :enter,
    )

    # verify tags
    tags = @browser.find_elements({ css: '.content.active .js-tag' })
    assert(tags)
    assert(tags[0])
    tags.each {|element|
      text = element.text
      if text == 'tag1'
        assert(true, 'tag1 exists')
      elsif text == 'tag 2'
        assert(true, 'tag 2 exists')
      elsif text == 'tag3'
        assert(true, 'tag3 exists')
      elsif text == 'tag4'
        assert(true, 'tag4 exists')
      else
        assert(false, "invalid tag '#{text}'")
      end
    }

    # reload browser
    reload()

    # verify tags
    tags = @browser.find_elements({ css: '.content.active .js-tag' })
    assert(tags)
    assert(tags[0])
    tags.each {|element|
      text = element.text
      if text == 'tag1'
        assert(true, 'tag1 exists')
      elsif text == 'tag 2'
        assert(true, 'tag 2 exists')
      elsif text == 'tag3'
        assert(true, 'tag3 exists')
      elsif text == 'tag4'
        assert(true, 'tag4 exists')
      else
        assert(false, "invalid tag '#{text}'")
      end
    }
  end

  def test_link

    @browser = browser_instance
    login(
      username: 'agent1@example.com',
      password: 'test',
      url: browser_url,
    )
    tasks_close_all()

    ticket1 = ticket_create(
      data: {
        customer: 'nico',
        group: 'Users',
        title: 'some subject - link#1',
        body: 'some body - link#1',
      },
    )

    ticket2 = ticket_create(
      data: {
        customer: 'nico',
        group: 'Users',
        title: 'some subject - link#2',
        body: 'some body - link#2',
      },
    )

    click(
      css: '.content.active .links .js-add',
    )
    sleep 2

    set(
      css: '.content.active .modal-body [name="ticket_number"]',
      value: ticket1[:number],
    )
    select(
      css: '.content.active .modal-body [name="link_type"]',
      value: 'normal',
    )
    click(
      css: '.content.active .modal-footer .js-submit',
    )

    watch_for(
      css: '.content.active .ticketLinks',
      value: ticket1[:title],
    )

    reload()

    watch_for(
      css: '.content.active .ticketLinks',
      value: ticket1[:title],
    )
    click(
      css: '.content.active .ticketLinks .js-delete'
    )
    watch_for_disappear(
      css: '.content.active .ticketLinks',
      value: ticket1[:title],
    )

    reload()

    watch_for_disappear(
      css: '.content.active .ticketLinks',
      value: ticket1[:title],
    )

  end

end
