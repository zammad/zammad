// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { flushPromises, mount } from '@vue/test-utils'
import SparkMD5 from 'spark-md5'
import { useRoute, type RouteLocationNormalizedLoadedGeneric } from 'vue-router'

import {
  destroyComponent,
  pushComponent,
} from '#shared/components/DynamicInitializer/manage.ts'

import {
  getOverlayContainerMeta,
  getRouteIdentifier,
  useOverlayContainer,
} from '../useOverlayContainer.ts'

vi.mock('#shared/components/DynamicInitializer/manage.ts', () => {
  return {
    destroyComponent: vi.fn(),
    pushComponent: vi.fn(),
  }
})

vi.mock('vue-router', () => ({
  useRoute: vi.fn(),
}))

const mockedUseRoute = vi.mocked(useRoute)

const inContext = (
  fn: () => void,
  route: Partial<RouteLocationNormalizedLoadedGeneric>,
) => {
  mockedUseRoute.mockReturnValue(route as RouteLocationNormalizedLoadedGeneric)

  const component = {
    setup() {
      fn()
      return () => null
    },
  }
  return mount(component)
}

describe('use dialog usage', () => {
  beforeEach(() => {
    const { options } = getOverlayContainerMeta('dialog')
    options.clear()
  })

  test('name and component are required', () => {
    inContext(
      () => {
        // @ts-expect-error - component is required
        useOverlayContainer('dialog', { name: 'name' })
      },
      {
        path: '/example',
        meta: {
          requiresAuth: true,
          requiredPermission: null,
        },
      },
    )

    inContext(
      () => {
        // @ts-expect-error - name is required
        useOverlayContainer('dialog', {
          component: vi.fn(),
        })
      },
      {
        path: '/example',
        meta: {
          requiresAuth: true,
          requiredPermission: null,
        },
      },
    )

    inContext(
      () => {
        useOverlayContainer('dialog', {
          name: 'name',
          component: vi.fn(),
        })
      },
      {
        path: '/example',
        meta: {
          requiresAuth: true,
          requiredPermission: null,
        },
      },
    )
  })

  test('adds and removes meta data', async () => {
    const vm = inContext(
      () => {
        useOverlayContainer('dialog', {
          name: 'name',
          component: vi.fn(),
        })
      },
      {
        name: 'Example',
        path: '/example',
        meta: {
          requiresAuth: true,
          requiredPermission: null,
        },
      },
    )
    const { options } = getOverlayContainerMeta('dialog')

    expect(options.size).toBe(1)
    expect(options.has('name_Example')).toBe(true)

    vm.unmount()

    await flushPromises()

    expect(options.size).toBe(0)
    expect(options.has('name_Example')).toBe(false)
  })

  test('opens and closes dialog', async () => {
    const component = vi.fn().mockResolvedValue({})

    let dialog!: ReturnType<typeof useOverlayContainer>

    inContext(
      () => {
        dialog = useOverlayContainer('dialog', {
          name: 'name',
          component,
        })
      },
      {
        name: 'Example',
        path: '/example',
        meta: {
          requiresAuth: true,
          requiredPermission: null,
        },
      },
    )

    await dialog.open()

    const { opened } = getOverlayContainerMeta('dialog')

    expect(dialog.isOpened.value).toBe(true)
    expect(component).toHaveBeenCalled()
    expect(opened.value.has('name_Example')).toBe(true)
    expect(pushComponent).toHaveBeenCalledWith(
      'dialog',
      'name_Example',
      expect.anything(),
      {},
    )

    await dialog.close()

    expect(dialog.isOpened.value).toBe(false)
    expect(opened.value.has('name_Example')).toBe(false)
    expect(destroyComponent).toHaveBeenCalledWith('dialog', 'name_Example')
  })

  test('prefetch starts loading', async () => {
    const component = vi.fn().mockResolvedValue({})

    let dialog!: ReturnType<typeof useOverlayContainer>
    inContext(
      () => {
        dialog = useOverlayContainer('dialog', {
          name: 'name',
          component,
        })
      },
      {
        name: 'Example',
        path: '/example',
        meta: {
          requiresAuth: true,
          requiredPermission: null,
        },
      },
    )

    await dialog.prefetch()
    expect(component).toHaveBeenCalled()
  })

  test('hooks are called', async () => {
    const component = vi.fn().mockResolvedValue({})
    const beforeOpen = vi.fn()
    const afterClose = vi.fn()

    let flyout!: ReturnType<typeof useOverlayContainer>
    inContext(
      () => {
        flyout = useOverlayContainer('flyout', {
          name: 'name',
          component,
          beforeOpen,
          afterClose,
        })
      },
      {
        name: 'Example',
        path: '/example',
        meta: {
          requiresAuth: true,
          requiredPermission: null,
        },
      },
    )

    await flyout.open()

    expect(beforeOpen).toHaveBeenCalled()
    expect(afterClose).not.toHaveBeenCalled()

    await flyout.close()

    expect(afterClose).toHaveBeenCalled()
  })
})

describe('getRouteIdentifier', () => {
  test('returns only the name if pageKey is not set and no params are present', () => {
    const route = {
      name: 'Example',
      path: '/example',
      params: {},
      meta: {
        requiresAuth: true,
        requiredPermission: null,
      },
      redirectedFrom: undefined,
    } as unknown as RouteLocationNormalizedLoadedGeneric

    expect(getRouteIdentifier(route)).toBe('Example')
  })

  test('returns pageKey if set', () => {
    const route = {
      name: 'Example',
      path: '/example',
      params: {},
      meta: {
        pageKey: 'ExamplePage',
        requiresAuth: true,
        requiredPermission: null,
      },
      matched: [],
      redirectedFrom: undefined,
    } as unknown as RouteLocationNormalizedLoadedGeneric

    expect(getRouteIdentifier(route)).toBe('ExamplePage')
  })

  test('creates hash from params', () => {
    const route = {
      name: 'Ticket',
      path: '/ticket/123',
      params: { internalId: '123' },
      meta: {
        requiresAuth: true,
        requiredPermission: null,
      },
      redirectedFrom: undefined,
    } as unknown as RouteLocationNormalizedLoadedGeneric

    const result = getRouteIdentifier(route)
    const expectedHash = SparkMD5.hash(JSON.stringify(route.params))
    expect(result).toBe(`Ticket_${expectedHash}`)
  })
})
