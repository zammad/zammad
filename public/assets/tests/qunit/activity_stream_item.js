// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

window.onload = function() {

// Mirrors App.Controller#prepareForObjectListItem, which takes the creator from the local store.
const renderGroupItem = (attributes) => {
  const item = _.extend({
    id: 1,
    o_id: 1,
    object: 'Group',
    type: 'update',
    created_at: '2026-10-21T10:00:00.000Z',
  }, attributes)
  item.objectNative = App.Group.findNative(item.o_id)
  item.title = item.objectNative.displayName()
  item.created_by = App.User.findNative(item.created_by_id)

  return $('<div>').html(App.view('dashboard/activity_stream_item')({ item: item }))
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

App.Group.refresh([
  {
    id: 1,
    name: 'Users',
    active: true,
  },
])

QUnit.test('group activity by an existing user', assert => {
  const el = renderGroupItem({ created_by_id: 5 })

  assert.ok(el.find('.activity-text').text().includes('Nicole Braun'), 'message names the user')
})

QUnit.test('group activity by a user who no longer exists', assert => {
  const el = renderGroupItem({ created_by_id: 999 })

  assert.equal(el.find('.activity-entry').length, 1, 'entry is rendered')
  assert.equal(el.find('.activity-text').text().trim(), '', 'message stays empty')
})

}
