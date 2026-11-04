// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { beforeEach, expect, it } from 'vitest'
import { page, type Locator } from 'vitest/browser'
import { defineComponent, Fragment, h } from 'vue'

import { mountComponent } from '#tests/browser/utils.ts'

import { useStickyHeader } from '#shared/composables/useStickyHeader.ts'

const Component = defineComponent({
  setup() {
    const { headerElement, stickyStyles } = useStickyHeader()
    return () => {
      return h(Fragment, [
        h(
          'header',
          {
            ref: headerElement,
            class: 'bg-red',
            style: ['height: 30px;', stickyStyles.value.header],
          },
          'Header',
        ),
        h('main', { style: ['height: 2000px;', stickyStyles.value.body] }, 'Content'),
      ])
    }
  },
})

// The tests of a file share one page, which keeps its scroll position.
beforeEach(() => {
  window.scrollTo(0, 0)
})

// The header is moved out of the viewport, but stays visible in terms of its styles, so a
//   shown header has to be completely in the viewport, a hidden one not at all.
const expectShown = async (header: Locator) => {
  await expect.element(header).toBeVisible()
  await expect.element(header).toBeInViewport({ ratio: 1 })
}

it('shows header when scroll is less than header height, and hides it afterwards', async () => {
  await mountComponent(Component)
  const header = page.getByRole('banner')

  await expectShown(header)
  window.scrollTo(0, 20)
  await expectShown(header)
  window.scrollTo(0, 60)
  await expect.element(header).not.toBeInViewport()
})

it('shows header when scrolling up', async () => {
  await mountComponent(Component)
  const header = page.getByRole('banner')

  await expectShown(header)
  window.scrollTo(0, 60)
  await expect.element(header).not.toBeInViewport()
  window.scrollTo(0, 20)
  await expectShown(header)
})
