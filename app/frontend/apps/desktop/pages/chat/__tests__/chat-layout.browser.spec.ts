// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { beforeEach, describe, expect, it, vi } from 'vitest'
import { page } from 'vitest/browser'
import { config } from 'vitest-browser-vue'
import { computed, defineComponent, h, KeepAlive, nextTick, ref } from 'vue'

import { mountComponent } from '#tests/browser/utils.ts'

import { waitForAnimationFrame } from '#shared/utils/helpers.ts'

import {
  currentAgent,
  mockAgentState,
  mockChatSessions,
  runningSession,
} from '#desktop/entities/chat/__tests__/mocks/chat-data.ts'

import ChatWorkspace from '../components/ChatWorkspace.vue'

// The test mode switches every transition off; the motion is what some of these cases are about.
const { reducedMotion } = await vi.hoisted(async () => {
  const { ref } = await import('vue')

  return { reducedMotion: ref(false) }
})

vi.mock('#shared/composables/useReducedMotion.ts', () => ({
  useReducedMotion: () => ({
    hasReducedMotion: computed(() => reducedMotion.value),
    scrollBehavior: computed(() => (reducedMotion.value ? 'instant' : 'smooth')),
  }),
}))

// Vue Test Utils renders a transition group without its transitions unless told otherwise.
config.global.stubs = { transition: false, 'transition-group': false }

const sessionIds = ref<string[]>([])

const windowToReveal = ref<string>()

// What the page leaves the workspace next to the sidebar; the whole viewport unless a case narrows it.
const pageWidth = ref('100vw')

// The workspace fills the page, as the chat page gives it its height.
// eslint-disable-next-line vue/one-component-per-file
const Page = defineComponent({
  setup() {
    return () =>
      h('div', { class: 'flex h-screen flex-col', style: { width: pageWidth.value } }, [
        h(ChatWorkspace, {
          sessionIds: sessionIds.value,
          windowToReveal: windowToReveal.value,
          'onUpdate:windowToReveal': (id?: string) => {
            windowToReveal.value = id
          },
          class: 'h-full',
        }),
      ])
  },
})

const isPageShown = ref(true)

// The layout keeps the chat page alive while the agent is on another one.
// eslint-disable-next-line vue/one-component-per-file
const KeptPage = defineComponent({
  setup() {
    return () => h(KeepAlive, null, () => (isPageShown.value ? h(Page) : h('p', 'Elsewhere')))
  },
})

const windows = () => page.getByRole('region').elements() as HTMLElement[]

const workspace = () => windows()[0].parentElement as HTMLElement

const rects = () => windows().map((element) => element.getBoundingClientRect())

const rows = () => [...new Set(rects().map((rect) => Math.round(rect.top)))]

const openWindows = async (count: number, component = Page) => {
  const sessions = Array.from({ length: count }, (_, index) =>
    runningSession(index + 1, currentAgent),
  )

  mockAgentState({ runningSessions: sessions })
  mockChatSessions(sessions)

  sessionIds.value = sessions.map((session) => session.id)

  await mountComponent(
    component,
    {},
    { config: { chat: true }, permissions: ['chat.agent'], userId: currentAgent.id },
  )

  await expect.poll(() => windows().length).toBe(count)
}

const expectEqual = (values: number[]) => {
  const [first, ...rest] = values

  rest.forEach((value) => expect(value).toBeCloseTo(first, 0))
}

const expectCarousel = () => {
  expect(rows()).toHaveLength(1)
  rects().forEach((rect) => expect(rect.width).toBeCloseTo(workspace().clientWidth, 0))

  expect(workspace().scrollWidth).toBeGreaterThan(workspace().clientWidth)
  expect(getComputedStyle(workspace()).scrollSnapType).toMatch(/^x /)
  expect(getComputedStyle(windows()[0]).scrollSnapAlign).toBe('center')
}

describe('Chat workspace layout', () => {
  beforeEach(() => {
    reducedMotion.value = true
    sessionIds.value = []
    windowToReveal.value = undefined
    pageWidth.value = '100vw'
    isPageShown.value = true
  })

  describe('from the small-screen breakpoint up', () => {
    beforeEach(() => page.viewport(1520, 1000))

    it('puts four windows of equal width in a row and the fifth alone in a second row of the same height', async () => {
      await openWindows(5)

      const [first, second, third, fourth, fifth] = rects()

      expectEqual([first.top, second.top, third.top, fourth.top])
      expectEqual([first.width, second.width, third.width, fourth.width])
      expect(second.left).toBeGreaterThan(first.right)

      expect(fifth.top).toBeGreaterThan(first.bottom)
      expect(fifth.width).toBeCloseTo(workspace().clientWidth, 0)

      expectEqual([first.height, fifth.height])
      expect(first.height + fifth.height).toBeLessThan(workspace().clientHeight)

      expect(workspace().scrollWidth).toBe(workspace().clientWidth)
      expect(workspace().scrollHeight).toBe(workspace().clientHeight)
    })

    it('makes three rows of equal height out of nine windows', async () => {
      await openWindows(9)

      expect(rows()).toHaveLength(3)
      expectEqual(rects().map((rect) => rect.height))
      expect(workspace().scrollHeight).toBe(workspace().clientHeight)
    })

    it('lets a single window take the whole workspace', async () => {
      await openWindows(1)

      const [only] = rects()

      expect(only.width).toBeCloseTo(workspace().clientWidth, 0)
      expect(only.height).toBeCloseTo(workspace().clientHeight, 0)
    })
  })

  describe('below the small-screen breakpoint', () => {
    beforeEach(() => page.viewport(1020, 760))

    // How far the window is from where the row shows it, at its start as each window is as wide
    //   as the row; the scroll lands on whole pixels, the row's width need not.
    const distanceFromView = (index: number) =>
      Math.abs(
        windows()[index].getBoundingClientRect().left - workspace().getBoundingClientRect().left,
      )

    it('lines the windows up in one snapping row, each as wide as the workspace', async () => {
      await openWindows(5)

      expectCarousel()
    })

    describe('when the agent opens a conversation from another page', () => {
      const opened = runningSession(3, currentAgent).id

      it('scrolls to its open window once the page is back', async () => {
        await openWindows(3, KeptPage)

        isPageShown.value = false

        await nextTick()

        windowToReveal.value = opened

        await nextTick()

        expect(windowToReveal.value).toBe(opened)

        isPageShown.value = true

        await expect.poll(() => distanceFromView(2), { timeout: 1000 }).toBeLessThanOrEqual(1)

        expect(windowToReveal.value).toBeUndefined()
      })

      it('scrolls to its window on the first visit of the page', async () => {
        windowToReveal.value = opened

        await openWindows(3, KeptPage)

        await expect.poll(() => distanceFromView(2), { timeout: 1000 }).toBeLessThanOrEqual(1)

        expect(windowToReveal.value).toBeUndefined()
      })
    })

    describe('when the agent accepts a conversation', () => {
      const accepted = runningSession(4, currentAgent).id

      const openAccepted = () => {
        sessionIds.value = [...sessionIds.value, accepted]
      }

      it('scrolls to its window once the window has grown into the row', async () => {
        reducedMotion.value = false

        await openWindows(3)

        openAccepted()
        windowToReveal.value = accepted

        await nextTick()

        expect(workspace().scrollLeft).toBe(0)

        await expect.poll(() => distanceFromView(3), { timeout: 2500 }).toBeLessThanOrEqual(1)

        expect(windowToReveal.value).toBeUndefined()
      })

      it('scrolls to its window when the window opens only after the acceptance', async () => {
        await openWindows(3)

        windowToReveal.value = accepted

        await nextTick()

        expect(windowToReveal.value).toBe(accepted)

        openAccepted()

        await expect.poll(() => distanceFromView(3), { timeout: 1000 }).toBeLessThanOrEqual(1)

        expect(windowToReveal.value).toBeUndefined()
      })

      it('scrolls to its window when the window opened before the acceptance', async () => {
        await openWindows(3)

        openAccepted()

        await expect.poll(() => windows().length).toBe(4)

        // Without the motion, the window is done entering two frames after it was added.
        await waitForAnimationFrame()
        await waitForAnimationFrame()
        await waitForAnimationFrame()

        expect(workspace().scrollLeft).toBe(0)

        windowToReveal.value = accepted

        await expect.poll(() => distanceFromView(3), { timeout: 1000 }).toBeLessThanOrEqual(1)
      })

      it('leaves the row where it is for a window that opens otherwise', async () => {
        reducedMotion.value = false

        await openWindows(3)

        openAccepted()

        await nextTick()

        const opened = windows()[3]

        await expect.poll(() => getComputedStyle(opened).transform, { timeout: 1500 }).toBe('none')

        expect(workspace().scrollLeft).toBe(0)
        expect(distanceFromView(0)).toBeLessThanOrEqual(1)
      })
    })
  })

  describe('on the smallest screen from the breakpoint up, next to the sidebar', () => {
    beforeEach(async () => {
      await page.viewport(1024, 768)

      // What the default sidebar and the page's padding leave the workspace.
      pageWidth.value = '732px'
    })

    it('still puts four windows in a row, with their disconnect button down to its icon', async () => {
      await openWindows(5)

      const [first, second, third, fourth, fifth] = rects()

      expectEqual([first.top, second.top, third.top, fourth.top])
      expect(fifth.top).toBeGreaterThan(first.bottom)
      expect(workspace().scrollWidth).toBe(workspace().clientWidth)

      const buttons = page.getByRole('button', { name: 'Disconnect' }).elements()

      expect(buttons).toHaveLength(5)

      buttons.forEach((button, index) =>
        expect(button.getBoundingClientRect().right).toBeLessThan(rects()[index].right),
      )

      expect(buttons[0].getBoundingClientRect().width).toBeLessThan(
        buttons[4].getBoundingClientRect().width / 2,
      )
    })
  })

  describe('opening and closing', () => {
    beforeEach(() => page.viewport(1520, 1000))

    const widthOf = (index: number) => rects()[index].width

    it('scales a new window in while its neighbours make room', async () => {
      reducedMotion.value = false

      await openWindows(3)

      const widthBefore = widthOf(0)

      sessionIds.value = [...sessionIds.value, runningSession(4, currentAgent).id]

      await nextTick()

      const opened = windows()[3]

      expect(getComputedStyle(opened).transform).not.toBe('none')
      expect(opened.getBoundingClientRect().width).toBeLessThan(widthBefore / 2)

      await expect.poll(() => getComputedStyle(opened).transform, { timeout: 1500 }).toBe('none')

      expectEqual(rects().map((rect) => rect.width))
      expect(widthOf(0)).toBeLessThan(widthBefore)
    })

    it('keeps a closing window in the row while it scales out, and lets the others take the space', async () => {
      reducedMotion.value = false

      await openWindows(4)

      const widthBefore = widthOf(0)
      const closing = windows()[1]

      sessionIds.value = sessionIds.value.filter((_, index) => index !== 1)

      await nextTick()

      expect(windows()).toHaveLength(4)
      expect(closing.isConnected).toBe(true)

      await expect
        .poll(() => closing.getBoundingClientRect().width, { timeout: 1500 })
        .toBeLessThan(widthBefore / 2)

      expect(closing.isConnected).toBe(true)
      expect(getComputedStyle(closing).transform).not.toBe('none')

      await expect.poll(() => closing.isConnected, { timeout: 1500 }).toBe(false)

      expect(windows()).toHaveLength(3)
      expectEqual(rects().map((rect) => rect.width))
      expect(widthOf(0)).toBeGreaterThan(widthBefore)
    })

    it('shows and removes a window at once when reduced motion is preferred', async () => {
      await openWindows(3)

      sessionIds.value = [...sessionIds.value, runningSession(4, currentAgent).id]

      await nextTick()

      expect(getComputedStyle(windows()[3]).transform).toBe('none')
      expectEqual(rects().map((rect) => rect.width))

      const closing = windows()[1]

      sessionIds.value = sessionIds.value.filter((_, index) => index !== 1)

      await expect.poll(() => closing.isConnected, { timeout: 200 }).toBe(false)
    })
  })
})
