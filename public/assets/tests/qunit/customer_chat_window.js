// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

window.onload = function() {

QUnit.test('renaming a chat keeps the chat number in the header', assert => {
  const el = $('<div>').html(App.view('customer_chat/chat_window')({
    name: 'Support Chat',
    session: { id: 42, chat_id: 1, created_at: '2026-10-21T10:00:00.000Z' },
    chats: [],
  }))

  assert.equal(el.find('.js-name').text(), 'Support Chat')

  el.find('.js-name').text('VIP customer')

  assert.equal(el.find('.chat-name').text().trim(), 'VIP customer #42')
  assert.equal(el.find('.js-info').text(), 'VIP customer #42')
})

QUnit.test('transfer list shows topic names as text', assert => {
  const el = $('<div>').html(App.view('customer_chat/chat_window')({
    name: 'Support Chat',
    session: { id: 42, chat_id: 1, created_at: '2026-10-21T10:00:00.000Z' },
    chats: [{ id: 2, name: '<b>Sales</b>' }],
  }))

  assert.equal(el.find('.js-transferChat').text(), '<b>Sales</b>')
  assert.equal(el.find('.js-transferChat b').length, 0)
})

}
