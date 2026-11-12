// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { beforeEach, describe, expect, it } from 'vitest'
import { page } from 'vitest/browser'
import { config } from 'vitest-browser-vue'
import { defineComponent, h } from 'vue'

import { mountComponent } from '#tests/browser/utils.ts'

import { EnumChatSessionState } from '#shared/graphql/types.ts'

import {
  chatSession,
  currentAgent,
  mockAgentState,
  mockChatSessions,
  salesTopic,
  waitingSessions,
  supportTopic,
} from '#desktop/entities/chat/__tests__/mocks/chat-data.ts'
import { useChatWindowsStore } from '#desktop/entities/chat/stores/chatWindows.ts'

import Chat from '../views/Chat.vue'

// Vue Test Utils puts an element of its own in place of a transition, which has no height to pass on.
config.global.stubs = { transition: false, 'transition-group': false }

// Inside the main area, which hides what overflows it, not pushed below it by the windows' area.
const expectInView = (element: Element) => {
  const main = document.querySelector('main')!.getBoundingClientRect()
  const { top, bottom } = element.getBoundingClientRect()

  expect(top).toBeGreaterThan(main.top)
  expect(bottom).toBeLessThan(main.bottom)
}

// The page fills the screen, as the layout of the app gives it its height.
const Screen = defineComponent({
  setup: () => () => h('div', { class: 'flex h-screen flex-col' }, [h(Chat)]),
})

const visitPage = () =>
  mountComponent(
    Screen,
    {},
    { config: { chat: true }, permissions: ['chat.agent'], userId: currentAgent.id },
  )

// What a click at the middle of the element would hit, not something laid over it.
const expectClickable = (element: Element) => {
  const { left, top, width, height } = element.getBoundingClientRect()

  expect(element.contains(document.elementFromPoint(left + width / 2, top + height / 2))).toBe(true)
}

describe('Chat page in the browser', () => {
  beforeEach(() => page.viewport(1280, 800))

  it('lets the agent without a subscribed topic open the settings from the page', async () => {
    // Among several topics the agent has to choose; a single one the server takes on its own.
    mockAgentState({ topics: [salesTopic, supportTopic] })

    await visitPage()

    const button = page.getByRole('button', { name: 'Settings' })

    await expect.element(button).toBeVisible()
    expectClickable(button.element())
  })

  it('shows the empty page in the middle of the page', async () => {
    mockAgentState()

    await visitPage()

    const heading = page.getByRole('heading', { name: 'No waiting customers' })

    await expect.element(heading).toBeVisible()
    expectInView(heading.element())
  })

  it('shows the empty page in the middle of the page once the last window is closed', async () => {
    // A conversation that has ended, which is what lets the agent close its window.
    const ended = chatSession(1, { state: EnumChatSessionState.Closed, user: currentAgent })

    mockAgentState()
    mockChatSessions([ended])

    await visitPage()

    useChatWindowsStore().openWindow(ended.id)

    await page.getByRole('button', { name: 'Close window' }).click()

    const heading = page.getByRole('heading', { name: 'No waiting customers' })

    await expect.element(heading).toBeVisible()
    await expect.poll(() => page.getByRole('region').elements()).toHaveLength(0)
    expectInView(heading.element())
  })

  it('shows the waiting customers in the middle of the page', async () => {
    mockAgentState({ waitingQueues: [{ topic: supportTopic, sessions: waitingSessions(2) }] })

    await visitPage()

    const button = page.getByRole('button', { name: 'Accept chat' })

    await expect.element(button).toBeVisible()
    expectInView(button.element())
    expectClickable(button.element())
  })
})
