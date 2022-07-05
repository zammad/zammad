// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '@tests/support/components/visitView'

describe('visiting /notifications', () => {
  test('can mark all notification as read', async () => {
    const view = await visitView('/notifications')

    console.log = vi.fn()

    await view.events.click(view.getByText('Mark all as read'))

    expect(console.log).toHaveBeenCalledWith('mark read', ['154362', '253223'])
  })

  test('deleting notifications actually deletes them', async () => {
    const view = await visitView('/notifications')

    console.log = vi.fn()
    await view.events.click(view.getAllByIconName('trash')[0])

    expect(console.log).toHaveBeenCalledWith(
      'remove',
      expect.objectContaining({ id: '154362' }),
    )
  })

  // TODO no test, because api is mocked
  test.todo("doesn't show 'remove all' if all are read")
})
