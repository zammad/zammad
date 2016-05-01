# encoding: utf-8
require 'browser_test_helper'

class AgentTicketActionLevel8Test < TestCase
  def test_a_tags

    @browser = browser_instance
    login(
      username: 'agent1@example.com',
      password: 'test',
      url: browser_url,
    )
    tasks_close_all()

    # set tag (by tab)
    ticket1 = ticket_create(
      data: {
        customer: 'nico',
        group: 'Users',
        title: 'some subject 123äöü - tags 1',
        body: 'some body 123äöü - tags 1',
      },
      do_not_submit: true,
    )
    sleep 1
    set(
      css: '.active .ticket-form-bottom .token-input',
      value: 'tag1, tag2',
    )
    sendkey(
      value: :tab,
    )

    # reload browser
    sleep 6
    reload()
    sleep 2

    click(
      css: '.active .newTicket button.js-submit',
    )
    sleep 5
    if @browser.current_url !~ /#{Regexp.quote('#ticket/zoom/')}/
      raise 'Unable to create ticket!'
    end

    # verify tags
    tags = @browser.find_elements({ css: '.content.active .js-tag' })
    assert(tags)
    assert(tags[0])
    tag1_found = false
    tag2_found = false
    tags.each {|element|
      text = element.text
      if text == 'tag1'
        tag1_found = true
        assert(true, 'tag1 exists')
      elsif text == 'tag2'
        tag2_found = true
        assert(true, 'tag2 exists')
      else
        assert(false, "invalid tag '#{text}'")
      end
    }
    assert(tag1_found, 'tag1 exists')
    assert(tag2_found, 'tag2 exists')

    # set tag (by blur)
    ticket2 = ticket_create(
      data: {
        customer: 'nico',
        group: 'Users',
        title: 'some subject 123äöü - tags 2',
        body: 'some body 123äöü - tags 2',
      },
      do_not_submit: true,
    )
    sleep 1
    set(
      css: '.active .ticket-form-bottom .token-input',
      value: 'tag3, tag4',
    )
    click(
      css: '#global-search',
    )

    click(
      css: '.active .newTicket button.js-submit',
    )
    sleep 5
    if @browser.current_url !~ /#{Regexp.quote('#ticket/zoom/')}/
      raise 'Unable to create ticket!'
    end

    # verify tags
    tags = @browser.find_elements({ css: '.content.active .js-tag' })
    assert(tags)
    assert(tags[0])
    tag3_found = false
    tag4_found = false
    tags.each {|element|
      text = element.text
      if text == 'tag3'
        tag3_found = true
        assert(true, 'tag 3 exists')
      elsif text == 'tag4'
        tag4_found = true
        assert(true, 'tag 4 exists')
      else
        assert(false, "invalid tag '#{text}'")
      end
    }
    assert(tag3_found, 'tag3 exists')
    assert(tag4_found, 'tag4 exists')

    ticket3 = ticket_create(
      data: {
        customer: 'nico',
        group: 'Users',
        title: 'some subject 123äöü - tags 3',
        body: 'some body 123äöü - tags 3',
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
    sleep 0.5

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
    sleep 0.5

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
    sleep 0.5

    # set tag #5
    click(
      css: '.content.active .js-newTagLabel',
    )
    set(
      css: '.content.active .js-newTagInput',
      value: 'tag5',
    )
    click(
      css: '#global-search',
    )
    sleep 0.5

    # verify tags
    tags = @browser.find_elements({ css: '.content.active .js-tag' })
    assert(tags)
    assert(tags[0])
    tag1_found = false
    tag2_found = false
    tag3_found = false
    tag4_found = false
    tag5_found = false
    tags.each {|element|
      text = element.text
      if text == 'tag1'
        tag1_found = true
        assert(true, 'tag1 exists')
      elsif text == 'tag 2'
        tag2_found = true
        assert(true, 'tag 2 exists')
      elsif text == 'tag3'
        tag3_found = true
        assert(true, 'tag3 exists')
      elsif text == 'tag4'
        tag4_found = true
        assert(true, 'tag4 exists')
      elsif text == 'tag5'
        tag5_found = true
        assert(true, 'tag5 exists')
      else
        assert(false, "invalid tag '#{text}'")
      end
    }
    assert(tag1_found, 'tag1 exists')
    assert(tag2_found, 'tag2 exists')
    assert(tag3_found, 'tag3 exists')
    assert(tag4_found, 'tag4 exists')
    assert(tag5_found, 'tag5 exists')

    # reload browser
    reload()

    # verify tags
    tags = @browser.find_elements({ css: '.content.active .js-tag' })
    assert(tags)
    assert(tags[0])
    tag1_found = false
    tag2_found = false
    tag3_found = false
    tag4_found = false
    tag5_found = false
    tags.each {|element|
      text = element.text
      if text == 'tag1'
        tag1_found = true
        assert(true, 'tag1 exists')
      elsif text == 'tag 2'
        tag2_found = true
        assert(true, 'tag 2 exists')
      elsif text == 'tag3'
        tag3_found = true
        assert(true, 'tag3 exists')
      elsif text == 'tag4'
        tag4_found = true
        assert(true, 'tag4 exists')
      elsif text == 'tag5'
        tag5_found = true
        assert(true, 'tag5 exists')
      else
        assert(false, "invalid tag '#{text}'")
      end
    }
    assert(tag1_found, 'tag1 exists')
    assert(tag2_found, 'tag2 exists')
    assert(tag3_found, 'tag3 exists')
    assert(tag4_found, 'tag4 exists')
    assert(tag5_found, 'tag5 exists')
  end

  def test_b_link

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
      value: 'Normal',
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
