// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

window.onload = function() {

// Mirrors App.Controller#prepareForObjectListItem, which takes the creator from the local store.
const renderItem = (attributes) => {
  const item = _.extend({
    id: 1,
    o_id: 1,
    object: 'Ticket',
    seen: false,
    link: '',
    created_at: '2026-10-21T10:00:00.000Z',
  }, attributes)
  item.created_by = App.User.findNative(item.created_by_id)

  return $('<div>').html(App.view('widget/online_notification_item')({ item: item }))
}

App.User.refresh([
  {
    id: 5,
    login: 'nicole.braun@zammad.org',
    firstname: 'Nicole',
    lastname: 'Braun',
    active: true,
  },
])

QUnit.test('notification by an existing user', assert => {
  const el = renderItem({ created_by_id: 5 })

  assert.equal(el.find('a.activity-avatar').attr('href'), App.User.findNative(5).uiUrl())
  assert.equal(el.find('.activity-avatar .user-popover').length, 1, 'avatar opens the user popover')
})

QUnit.test('notification by a user who no longer exists', assert => {
  const el = renderItem({ created_by_id: 999 })

  assert.equal(el.find('.activity-avatar .avatar--unique').text().trim(), '??')
  assert.notOk(el.find('.activity-avatar').attr('href'), 'avatar links nowhere')
  assert.equal(el.find('.user-popover').length, 0, 'avatar opens no user popover')
})

QUnit.test('AI notification by a user who no longer exists', assert => {
  const el = renderItem({ created_by_id: 999, meta: { created_by_ai: true } })

  assert.equal(el.find('.activity-ai-avatar').length, 1)
  assert.notOk(el.find('.activity-ai-avatar').attr('href'), 'avatar links nowhere')
})

}
