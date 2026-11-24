// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

window.onload = function() {

QUnit.test('waiting list shows topic names as text', assert => {
  const el = $('<div>').html(App.view('customer_chat/chat_header')({
    chats: [
      { id: 1, name: '[Sales](https://example.org)' },
      { id: 2, name: 'Support' },
    ],
  }))

  assert.equal(el.find('.js-waitingCustomers a').length, 0)
  assert.ok(el.find('.js-waitingCustomers').first().text().includes('[Sales](https://example.org)'))
})

}
