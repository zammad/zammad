// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { mount } from '@vue/test-utils'
import { defineComponent, h, KeepAlive, nextTick, ref } from 'vue'

import { useKnowledgeBaseContentUpdates } from '../useKnowledgeBaseContentUpdates.ts'

// The store is stood in for, so a ping can be delivered without a subscription behind it: what is
//   under test is which pings reach the consumer, not how they arrive.
const listeners: Array<(payload: unknown) => void> = []

vi.mock('#desktop/entities/knowledge-base/stores/knowledgeBase.ts', () => ({
  useKnowledgeBaseStore: () => ({
    contentUpdates: {
      onResult: (callback: (payload: unknown) => void) => {
        listeners.push(callback)

        return {
          off: () => {
            const index = listeners.indexOf(callback)
            if (index !== -1) listeners.splice(index, 1)
          },
        }
      },
    },
  }),
}))

const ping = async (affectedCategoryIds: string[]) => {
  listeners.forEach((callback) =>
    callback({ data: { knowledgeBaseContentUpdates: { affectedCategoryIds } } }),
  )

  await nextTick()
}

const CATEGORY_ID = 'gid://zammad/KnowledgeBaseCategory/1'

// Rendered inside a KeepAlive with a `v-if`, which is how a page of a kept-alive section comes and
//   goes: the instance is deactivated rather than unmounted, and reactivated when it is back.
const mountConsumer = () => {
  const updates: string[][] = []
  const onScreen = ref(true)

  const Consumer = defineComponent({
    setup() {
      useKnowledgeBaseContentUpdates((affectedCategoryIds) => updates.push(affectedCategoryIds))

      return () => h('div', 'consumer')
    },
  })

  const Host = defineComponent({
    setup() {
      return () => h(KeepAlive, null, { default: () => (onScreen.value ? h(Consumer) : null) })
    },
  })

  mount(Host)

  return { updates, onScreen }
}

describe('useKnowledgeBaseContentUpdates', () => {
  beforeEach(() => {
    listeners.length = 0
  })

  it('hands over a ping while the view is on screen', async () => {
    const { updates } = mountConsumer()

    await ping([CATEGORY_ID])

    expect(updates).toEqual([[CATEGORY_ID]])
  })

  it('holds pings back while the view is off screen, and catches up once when it returns', async () => {
    const { updates, onScreen } = mountConsumer()

    onScreen.value = false
    await nextTick()

    await ping([CATEGORY_ID])
    await ping([CATEGORY_ID])

    expect(updates, 'nothing while off screen').toEqual([])

    onScreen.value = true
    await nextTick()
    await nextTick()

    // One catch-up, with no affected categories: the skipped pings cannot be replayed, and an empty
    //   list is what every consumer reads as "may concern anything".
    expect(updates, 'one unconditional catch-up on return').toEqual([[]])
  })

  // Even with no ping seen: the store closes the subscription when the route leaves the knowledge
  //   base (`enabled: Boolean(activeLocale)`), so a change made while the page was away reaches
  //   nobody - and a page waiting for a ping it could never receive stays stale for as long as it
  //   is kept.
  it('catches up on return even when no ping was seen', async () => {
    const { updates, onScreen } = mountConsumer()

    onScreen.value = false
    await nextTick()

    onScreen.value = true
    await nextTick()
    await nextTick()

    expect(updates).toEqual([[]])
  })
})
