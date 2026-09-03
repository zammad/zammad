// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { flushPromises } from '@vue/test-utils'
import {
  defineComponent,
  h,
  KeepAlive,
  onActivated,
  onDeactivated,
  onMounted,
  onUnmounted,
} from 'vue'
import { RouterView } from 'vue-router'

import renderComponent, { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { useSectionPageCache } from '../useSectionPageCache.ts'

import type { RouteRecordRaw } from 'vue-router'

const log: string[] = []

const page = (name: string) =>
  defineComponent({
    name,
    setup() {
      onMounted(() => log.push(`${name} mounted`))
      onUnmounted(() => log.push(`${name} unmounted`))
      onActivated(() => log.push(`${name} activated`))
      onDeactivated(() => log.push(`${name} deactivated`))

      return () => h('div', name)
    },
  })

// A section, wired the way the real ones are.
const SectionWithCache = defineComponent({
  name: 'SectionWithCache',
  setup() {
    const cacheOnlyCurrentPage = useSectionPageCache()

    return () =>
      h(RouterView, null, {
        default: ({ Component }: { Component: unknown }) =>
          h(
            KeepAlive,
            { include: cacheOnlyCurrentPage(Component) },
            { default: () => (Component ? h(Component as never) : null) },
          ),
      })
  },
})

// Stands in for LayoutPage: it keeps a permanent section itself, which is what makes the section's
//   own cache matter in the first place.
const Shell = defineComponent({
  name: 'Shell',
  setup() {
    return () =>
      h(RouterView, null, {
        default: ({ Component }: { Component: unknown }) =>
          h(KeepAlive, null, { default: () => (Component ? h(Component as never) : null) }),
      })
  },
})

const routerRoutes: RouteRecordRaw[] = [
  // Where the harness mounts before the test navigates.
  { path: '/', name: 'Start', component: defineComponent({ setup: () => () => h('div') }) },
  {
    path: '/section',
    name: 'Section',
    component: SectionWithCache,
    children: [
      { path: 'first/:tab?', name: 'FirstPage', component: page('FirstPage') },
      { path: 'second', name: 'SecondPage', component: page('SecondPage') },
    ],
  },
  { path: '/elsewhere', name: 'Elsewhere', component: page('Elsewhere') },
]

// The teardown of the page left behind lands a tick after the switch, so give the queue room
//   before asserting that it did *not* happen.
const settle = async () => {
  await flushPromises()
  await flushPromises()
  await flushPromises()
}

const countOf = (entry: string) => log.filter((line) => line === entry).length

describe('useSectionPageCache', () => {
  beforeEach(() => {
    log.length = 0
  })

  it('destroys the page it leaves', async () => {
    renderComponent(Shell, { router: true, routerRoutes })

    const router = getTestRouter()
    await router.replace('/section/first')
    await settle()

    await router.push('/section/second')

    // Not just deactivated: a cache capped to one entry leaves the outgoing page behind instead,
    //   deactivated and dropped from the cache, with nothing able to reactivate or destroy it.
    await waitFor(() => {
      expect(log, 'the page left behind is torn down').toContain('FirstPage unmounted')
    })

    expect(
      countOf('FirstPage mounted') + countOf('SecondPage mounted') - countOf('FirstPage unmounted'),
      'one page of the section alive',
    ).toBe(1)
  })

  // The discriminating case. A cap of one gets this wrong: once the section has rendered the same
  //   page twice, the eviction deactivates it and drops it from the cache without ever unmounting
  //   it, so `FirstPage unmounted` never arrives.
  it('destroys the page it leaves after that page has re-rendered', async () => {
    renderComponent(Shell, { router: true, routerRoutes })

    const router = getTestRouter()
    await router.replace('/section/first')
    await settle()

    // Same page, new params - the section renders it a second time.
    await router.push('/section/first/details')
    await settle()

    expect(countOf('FirstPage mounted'), 'still the same instance').toBe(1)

    await router.push('/section/second')

    await waitFor(() => {
      expect(log, 'the page left behind is torn down').toContain('FirstPage unmounted')
    })
  })

  it('keeps the page on screen while the section itself is away', async () => {
    renderComponent(Shell, { router: true, routerRoutes })

    const router = getTestRouter()
    await router.replace('/section/first')
    await settle()

    // Leaving the section: the router has no page to render here any more, so without the cache the
    //   page would be unmounted and rebuilt on return.
    await router.push('/elsewhere')
    await settle()

    expect(log, 'kept, not destroyed').not.toContain('FirstPage unmounted')

    await router.push('/section/first')
    await settle()

    expect(countOf('FirstPage mounted'), 'the same instance came back').toBe(1)
    expect(log, 'reactivated rather than rebuilt').toContain('FirstPage activated')
  })
})
