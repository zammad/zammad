# encoding: utf-8
require 'test_helper'

class OverviewTest < ActiveSupport::TestCase

  test 'overview link' do
    UserInfo.current_user_id = 1
    overview = Overview.create!(
      name: 'Not Shown Admin 2',
      condition: {
        'ticket.state_id' => {
          operator: 'is',
          value: [1, 2, 3],
        },
      },
      order: {
        by: 'created_at',
        direction: 'DESC',
      },
      view: {
        d: %w(title customer state created_at),
        s: %w(number title customer state created_at),
        m: %w(number title customer state created_at),
        view_mode_default: 's',
      },
    )
    assert_equal(overview.link, 'not_shown_admin_2')
    overview.destroy!

    overview = Overview.create!(
      name: 'My assigned Tickets',
      condition: {
        'ticket.state_id' => {
          operator: 'is',
          value: [1, 2, 3],
        },
      },
      order: {
        by: 'created_at',
        direction: 'DESC',
      },
      view: {
        d: %w(title customer state created_at),
        s: %w(number title customer state created_at),
        m: %w(number title customer state created_at),
        view_mode_default: 's',
      },
    )
    assert_equal(overview.link, 'my_assigned_tickets')
    overview.destroy!

    overview = Overview.create!(
      name: 'Übersicht',
      condition: {
        'ticket.state_id' => {
          operator: 'is',
          value: [1, 2, 3],
        },
      },
      order: {
        by: 'created_at',
        direction: 'DESC',
      },
      view: {
        d: %w(title customer state created_at),
        s: %w(number title customer state created_at),
        m: %w(number title customer state created_at),
        view_mode_default: 's',
      },
    )
    assert_equal(overview.link, 'ubersicht')
    overview.destroy!

    overview = Overview.create!(
      name: "   Übersicht   \n",
      condition: {
        'ticket.state_id' => {
          operator: 'is',
          value: [1, 2, 3],
        },
      },
      order: {
        by: 'created_at',
        direction: 'DESC',
      },
      view: {
        d: %w(title customer state created_at),
        s: %w(number title customer state created_at),
        m: %w(number title customer state created_at),
        view_mode_default: 's',
      },
    )
    assert_equal(overview.link, 'ubersicht')
    overview.destroy!

    overview1 = Overview.create!(
      name: 'Meine Übersicht',
      condition: {
        'ticket.state_id' => {
          operator: 'is',
          value: [1, 2, 3],
        },
      },
      order: {
        by: 'created_at',
        direction: 'DESC',
      },
      view: {
        d: %w(title customer state created_at),
        s: %w(number title customer state created_at),
        m: %w(number title customer state created_at),
        view_mode_default: 's',
      },
    )
    assert_equal(overview1.link, 'meine_ubersicht')
    overview2 = Overview.create!(
      name: 'Meine Übersicht',
      condition: {
        'ticket.state_id' => {
          operator: 'is',
          value: [1, 2, 3],
        },
      },
      order: {
        by: 'created_at',
        direction: 'DESC',
      },
      view: {
        d: %w(title customer state created_at),
        s: %w(number title customer state created_at),
        m: %w(number title customer state created_at),
        view_mode_default: 's',
      },
    )
    assert(overview2.link.start_with?('meine_ubersicht'))
    assert_not_equal(overview1.link, overview2.link)
    overview1.destroy!
    overview2.destroy!

    overview = Overview.create!(
      name: 'Д дФ ф',
      condition: {
        'ticket.state_id' => {
          operator: 'is',
          value: [1, 2, 3],
        },
      },
      order: {
        by: 'created_at',
        direction: 'DESC',
      },
      view: {
        d: %w(title customer state created_at),
        s: %w(number title customer state created_at),
        m: %w(number title customer state created_at),
        view_mode_default: 's',
      },
    )
    assert_match(/^\d{1,3}$/, overview.link)
    overview.destroy!

    overview = Overview.create!(
      name: ' Д дФ ф abc ',
      condition: {
        'ticket.state_id' => {
          operator: 'is',
          value: [1, 2, 3],
        },
      },
      order: {
        by: 'created_at',
        direction: 'DESC',
      },
      view: {
        d: %w(title customer state created_at),
        s: %w(number title customer state created_at),
        m: %w(number title customer state created_at),
        view_mode_default: 's',
      },
    )
    assert_equal(overview.link, 'abc')
    overview.destroy!

    overview = Overview.create!(
      name: 'Übersicht',
      link: 'my_overview',
      condition: {
        'ticket.state_id' => {
          operator: 'is',
          value: [1, 2, 3],
        },
      },
      order: {
        by: 'created_at',
        direction: 'DESC',
      },
      view: {
        d: %w(title customer state created_at),
        s: %w(number title customer state created_at),
        m: %w(number title customer state created_at),
        view_mode_default: 's',
      },
    )
    assert_equal(overview.link, 'my_overview')

    overview.name = 'Übersicht2'
    overview.link = 'my_overview2'
    overview.save!

    assert_equal(overview.link, 'my_overview2')

    overview.destroy!

  end
end
