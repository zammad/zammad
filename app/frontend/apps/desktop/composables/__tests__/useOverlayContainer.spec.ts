// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { flushPromises, mount } from '@vue/test-utils'
import { useRoute, type RouteLocationNormalizedLoadedGeneric } from 'vue-router'

import {
  destroyComponent,
  pushComponent,
} from '#shared/components/DynamicInitializer/manage.ts'

import {
  getOverlayContainerMeta,
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
        path: '/example',
      },
    )
    const { options } = getOverlayContainerMeta('dialog')

    expect(options.size).toBe(1)
    expect(options.has('name_/example')).toBe(true)

    vm.unmount()

    await flushPromises()

    expect(options.size).toBe(0)
    expect(options.has('name_/example')).toBe(false)
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
        path: '/example',
      },
    )

    await dialog.open()

    const { opened } = getOverlayContainerMeta('dialog')

    expect(dialog.isOpened.value).toBe(true)
    expect(component).toHaveBeenCalled()
    expect(opened.value.has('name_/example')).toBe(true)
    expect(pushComponent).toHaveBeenCalledWith(
      'dialog',
      'name_/example',
      expect.anything(),
      {},
    )

    await dialog.close()

    expect(dialog.isOpened.value).toBe(false)
    expect(opened.value.has('name_/example')).toBe(false)
    expect(destroyComponent).toHaveBeenCalledWith('dialog', 'name_/example')
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
        path: '/example',
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
        path: '/example',
      },
    )

    await flyout.open()

    expect(beforeOpen).toHaveBeenCalled()
    expect(afterClose).not.toHaveBeenCalled()

    await flyout.close()

    expect(afterClose).toHaveBeenCalled()
  })
})
