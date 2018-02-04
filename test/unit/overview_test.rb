
require 'test_helper'

class OverviewTest < ActiveSupport::TestCase

  test 'overview link' do
    UserInfo.current_user_id = 1
    roles = Role.where(name: 'Agent')

    overview = Overview.create!(
      name: 'Not Shown Admin 2',
      roles: roles,
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
        d: %w[title customer state created_at],
        s: %w[number title customer state created_at],
        m: %w[number title customer state created_at],
        view_mode_default: 's',
      },
    )
    assert_equal(overview.link, 'not_shown_admin_2')
    overview.destroy!

    overview = Overview.create!(
      name: 'My assigned Tickets 2',
      roles: roles,
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
        d: %w[title customer state created_at],
        s: %w[number title customer state created_at],
        m: %w[number title customer state created_at],
        view_mode_default: 's',
      },
    )
    assert_equal(overview.link, 'my_assigned_tickets_2')
    overview.destroy!

    overview = Overview.create!(
      name: 'Übersicht',
      roles: roles,
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
        d: %w[title customer state created_at],
        s: %w[number title customer state created_at],
        m: %w[number title customer state created_at],
        view_mode_default: 's',
      },
    )
    assert_equal(overview.link, 'ubersicht')
    overview.destroy!

    overview = Overview.create!(
      name: "   Übersicht   \n",
      roles: roles,
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
        d: %w[title customer state created_at],
        s: %w[number title customer state created_at],
        m: %w[number title customer state created_at],
        view_mode_default: 's',
      },
    )
    assert_equal(overview.link, 'ubersicht')
    overview.destroy!

    overview1 = Overview.create!(
      name: 'Meine Übersicht',
      roles: roles,
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
        d: %w[title customer state created_at],
        s: %w[number title customer state created_at],
        m: %w[number title customer state created_at],
        view_mode_default: 's',
      },
    )
    assert_equal(overview1.link, 'meine_ubersicht')
    overview2 = Overview.create!(
      name: 'Meine Übersicht',
      roles: roles,
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
        d: %w[title customer state created_at],
        s: %w[number title customer state created_at],
        m: %w[number title customer state created_at],
        view_mode_default: 's',
      },
    )
    assert(overview2.link.start_with?('meine_ubersicht'))
    assert_not_equal(overview1.link, overview2.link)
    overview1.destroy!
    overview2.destroy!

    overview = Overview.create!(
      name: 'Д дФ ф',
      roles: roles,
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
        d: %w[title customer state created_at],
        s: %w[number title customer state created_at],
        m: %w[number title customer state created_at],
        view_mode_default: 's',
      },
    )
    assert_match(/^\d{1,3}$/, overview.link)
    overview.destroy!

    overview = Overview.create!(
      name: ' Д дФ ф abc ',
      roles: roles,
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
        d: %w[title customer state created_at],
        s: %w[number title customer state created_at],
        m: %w[number title customer state created_at],
        view_mode_default: 's',
      },
    )
    assert_equal(overview.link, 'abc')
    overview.destroy!

    overview = Overview.create!(
      name: 'Übersicht',
      link: 'my_overview',
      roles: roles,
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
        d: %w[title customer state created_at],
        s: %w[number title customer state created_at],
        m: %w[number title customer state created_at],
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

  test 'same url' do
    UserInfo.current_user_id = 1

    roles = Role.where(name: 'Agent')

    overview1 = Overview.create!(
      name: 'My own assigned Tickets',
      roles: roles,
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
        d: %w[title customer state created_at],
        s: %w[number title customer state created_at],
        m: %w[number title customer state created_at],
        view_mode_default: 's',
      },
    )
    assert_equal(overview1.link, 'my_own_assigned_tickets')

    overview2 = Overview.create!(
      name: 'My own assigned Tickets',
      roles: roles,
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
        d: %w[title customer state created_at],
        s: %w[number title customer state created_at],
        m: %w[number title customer state created_at],
        view_mode_default: 's',
      },
    )
    assert_equal(overview2.link, 'my_own_assigned_tickets_1')

    overview3 = Overview.create!(
      name: 'My own assigned Tickets',
      roles: roles,
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
        d: %w[title customer state created_at],
        s: %w[number title customer state created_at],
        m: %w[number title customer state created_at],
        view_mode_default: 's',
      },
    )
    assert_equal(overview3.link, 'my_own_assigned_tickets_2')

    overview1.destroy!
    overview2.destroy!
    overview3.destroy!
  end

  test 'priority rearrangement' do
    UserInfo.current_user_id = 1

    roles = Role.where(name: 'Agent')

    overview1 = Overview.create!(
      name: 'Overview1',
      link: 'my_overview',
      roles: roles,
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
        d: %w[title customer state created_at],
        s: %w[number title customer state created_at],
        m: %w[number title customer state created_at],
        view_mode_default: 's',
      },
      prio: 1,
    )

    overview2 = Overview.create!(
      name: 'Overview2',
      link: 'my_overview',
      roles: roles,
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
        d: %w[title customer state created_at],
        s: %w[number title customer state created_at],
        m: %w[number title customer state created_at],
        view_mode_default: 's',
      },
      prio: 2,
    )

    overview3 = Overview.create!(
      name: 'Overview3',
      link: 'my_overview',
      roles: roles,
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
        d: %w[title customer state created_at],
        s: %w[number title customer state created_at],
        m: %w[number title customer state created_at],
        view_mode_default: 's',
      },
      prio: 3,
    )

    overview2.prio = 3
    overview2.save!

    overviews = Overview.all.order(prio: :asc).pluck(:id)
    assert_equal(overview1.id, overviews[0])
    assert_equal(overview3.id, overviews[1])
    assert_equal(overview2.id, overviews[2])

    overview1.destroy!
    overview2.destroy!
    overview3.destroy!
  end
end
