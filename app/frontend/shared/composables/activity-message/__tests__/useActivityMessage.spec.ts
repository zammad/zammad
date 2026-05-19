// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import type { OnlineNotification } from '#shared/graphql/types.ts'

import { useActivityMessage } from '../useActivityMessage.ts'

const buildActivity = (overrides: Partial<OnlineNotification> = {}) =>
  ref({
    id: 'gid://zammad/OnlineNotification/1',
    objectName: 'Ticket',
    typeName: 'create',
    createdBy: {
      id: 'gid://zammad/User/2',
      fullname: 'Nicole Braun',
    },
    metaObject: {
      __typename: 'Ticket',
      id: 'gid://zammad/Ticket/1',
      internalId: 1,
      title: 'Welcome to Zammad',
    },
    ...overrides,
  } as OnlineNotification)

describe('useActivityMessage', () => {
  it('wraps the highlighted segment in <b> tags', () => {
    const activity = buildActivity()

    const { highlightedMessage } = useActivityMessage(activity)

    expect(highlightedMessage).toBe('Nicole Braun created ticket <b>Welcome to Zammad</b>')
  })

  it('escapes HTML in the meta object title', () => {
    const activity = buildActivity({
      metaObject: {
        __typename: 'Ticket',
        id: 'gid://zammad/Ticket/1',
        internalId: 1,
        title: '<img src=x onerror="alert(1)">',
      } as OnlineNotification['metaObject'],
    })

    const { highlightedMessage } = useActivityMessage(activity)

    expect(highlightedMessage).not.toContain('<img')
    expect(highlightedMessage).toBe(
      'Nicole Braun created ticket <b>&lt;img src=x onerror=&quot;alert(1)&quot;&gt;</b>',
    )
  })

  it('escapes HTML in the author name', () => {
    const activity = buildActivity({
      createdBy: {
        id: 'gid://zammad/User/2',
        fullname: '<script>alert(1)</script>',
      } as OnlineNotification['createdBy'],
    })

    const { highlightedMessage } = useActivityMessage(activity)

    expect(highlightedMessage).not.toContain('<script')
    expect(highlightedMessage).toContain('&lt;script&gt;alert(1)&lt;/script&gt;')
  })
})
