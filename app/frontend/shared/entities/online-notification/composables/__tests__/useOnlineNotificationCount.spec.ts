// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { defineComponent, h } from 'vue'

import { waitForGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import { renderComponent } from '#tests/support/components/index.ts'

import { OnlineNotificationsCountDocument } from '#shared/entities/online-notification/graphql/subscriptions/onlineNotificationsCount.api.ts'
import { getOnlineNotificationsCountSubscriptionHandler } from '#shared/entities/online-notification/graphql/subscriptions/onlineNotificationsCount.mocks.ts'

import { useOnlineNotificationCount } from '../useOnlineNotificationCount.ts'

const run = (options?: Parameters<typeof useOnlineNotificationCount>[0]) => {
  let result!: ReturnType<typeof useOnlineNotificationCount>

  renderComponent(
    defineComponent({
      setup() {
        result = useOnlineNotificationCount(options)
        return () => h('div')
      },
    }),
  )

  return result
}

describe('useOnlineNotificationCount', () => {
  it('subscribes to the count alone by default', async () => {
    const { unseenCount } = run()

    const [call] = await waitForGraphQLMockCalls(OnlineNotificationsCountDocument)
    expect(call.variables).toEqual({ withPushTags: false })

    await getOnlineNotificationsCountSubscriptionHandler().trigger({
      onlineNotificationsCount: { unseenCount: 3 },
    })

    expect(unseenCount.value).toBe(3)
  })

  it('asks for the push tags when opted in', async () => {
    const { unseenCount, unseenPushTags } = run({ withPushTags: true })

    const [call] = await waitForGraphQLMockCalls(OnlineNotificationsCountDocument)
    expect(call.variables).toEqual({ withPushTags: true })

    await getOnlineNotificationsCountSubscriptionHandler().trigger({
      onlineNotificationsCount: { unseenCount: 2, unseenPushTags: ['ticket-42'] },
    })

    expect(unseenCount.value).toBe(2)
    expect(unseenPushTags.value).toEqual(['ticket-42'])
  })
})
