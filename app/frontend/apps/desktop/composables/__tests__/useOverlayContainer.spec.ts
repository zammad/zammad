// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { flushPromises, mount } from '@vue/test-utils'

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

const inContext = (fn: () => void) => {
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
    // @ts-expect-error - component is required
    useOverlayContainer('dialog', { name: 'name' })
    // @ts-expect-error - name is required
    useOverlayContainer('dialog', {
      component: vi.fn(),
    })
    useOverlayContainer('dialog', {
      name: 'name',
      component: vi.fn(),
    })
  })

  test('adds and removes meta data', async () => {
    const vm = inContext(() => {
      useOverlayContainer('dialog', {
        name: 'name',
        component: vi.fn(),
      })
    })
    const { options } = getOverlayContainerMeta('dialog')

    expect(options.size).toBe(1)
    expect(options.has('name')).toBe(true)

    vm.unmount()

    await flushPromises()

    expect(options.size).toBe(0)
    expect(options.has('name')).toBe(false)
  })

  test('opens and closes dialog', async () => {
    const component = vi.fn().mockResolvedValue({})
    const dialog = useOverlayContainer('dialog', {
      name: 'name',
      component,
    })
    await dialog.open()

    const { opened } = getOverlayContainerMeta('dialog')

    expect(dialog.isOpened.value).toBe(true)
    expect(component).toHaveBeenCalled()
    expect(opened.value.has('name')).toBe(true)
    expect(pushComponent).toHaveBeenCalledWith(
      'dialog',
      'name',
      expect.anything(),
      {},
    )

    await dialog.close()

    expect(dialog.isOpened.value).toBe(false)
    expect(opened.value.has('name')).toBe(false)
    expect(destroyComponent).toHaveBeenCalledWith('dialog', 'name')
  })

  test('opens and closes already opned dialog', async () => {
    const component = vi.fn().mockResolvedValue({})
    const dialog = useOverlayContainer('dialog', {
      name: 'name',
      component,
    })
    const additionalDialog = useOverlayContainer('dialog', {
      name: 'additional-name',
      component,
    })

    await dialog.open()

    const { opened } = getOverlayContainerMeta('dialog')

    expect(dialog.isOpened.value).toBe(true)
    expect(component).toHaveBeenCalled()
    expect(opened.value.has('name')).toBe(true)
    expect(pushComponent).toHaveBeenCalledWith(
      'dialog',
      'name',
      expect.anything(),
      {},
    )

    await additionalDialog.open()

    expect(dialog.isOpened.value).toBe(false)
    expect(opened.value.has('name')).toBe(false)
    expect(destroyComponent).toHaveBeenCalledWith('dialog', 'name')

    expect(additionalDialog.isOpened.value).toBe(true)
    expect(component).toHaveBeenCalled()
    expect(opened.value.has('additional-name')).toBe(true)
    expect(pushComponent).toHaveBeenCalledWith(
      'dialog',
      'additional-name',
      expect.anything(),
      {},
    )
  })

  test('prefetch starts loading', async () => {
    const component = vi.fn().mockResolvedValue({})
    const dialog = useOverlayContainer('dialog', {
      name: 'name',
      component,
    })
    await dialog.prefetch()
    expect(component).toHaveBeenCalled()
  })

  test('hooks are called', async () => {
    const component = vi.fn().mockResolvedValue({})
    const beforeOpen = vi.fn()
    const afterClose = vi.fn()

    const dialog = useOverlayContainer('flyout', {
      name: 'name',
      component,
      beforeOpen,
      afterClose,
    })
    await dialog.open()

    expect(beforeOpen).toHaveBeenCalled()
    expect(afterClose).not.toHaveBeenCalled()

    await dialog.close()

    expect(afterClose).toHaveBeenCalled()
  })
})
